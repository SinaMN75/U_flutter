// windows.h's min/max macros break the C++/WinRT headers.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <NotificationActivationCallback.h>
#include <appmodel.h>
#include <propkey.h>
#include <propvarutil.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wrl/client.h>

#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.UI.Notifications.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "../common/u_platform.h"
#include "u_notification.h"

namespace u {

namespace {

namespace toast = winrt::Windows::UI::Notifications;
namespace xml = winrt::Windows::Data::Xml::Dom;
using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using Microsoft::WRL::ComPtr;
using platform::Narrow;
using platform::Widen;
using Sink = flutter::EventSink<EncodableValue>;
using StreamError = std::unique_ptr<flutter::StreamHandlerError<EncodableValue>>;

// --- argument helpers ------------------------------------------------------------

const EncodableValue* Arg(const EncodableMap& args, const char* key) {
  const auto it = args.find(EncodableValue(key));
  return it == args.end() ? nullptr : &it->second;
}

std::string Str(const EncodableMap& args, const char* key) {
  const EncodableValue* value = Arg(args, key);
  const std::string* text = value ? std::get_if<std::string>(value) : nullptr;
  return text ? *text : std::string();
}

bool Bool(const EncodableMap& args, const char* key) {
  const EncodableValue* value = Arg(args, key);
  const bool* flag = value ? std::get_if<bool>(value) : nullptr;
  return flag && *flag;
}

int64_t Int(const EncodableMap& args, const char* key, int64_t fallback) {
  const EncodableValue* value = Arg(args, key);
  if (value == nullptr) return fallback;
  if (const int32_t* i = std::get_if<int32_t>(value)) return *i;
  if (const int64_t* l = std::get_if<int64_t>(value)) return *l;
  if (const double* d = std::get_if<double>(value)) return static_cast<int64_t>(*d);
  return fallback;
}

const EncodableMap* MapArg(const EncodableMap& args, const char* key) {
  const EncodableValue* value = Arg(args, key);
  return value ? std::get_if<EncodableMap>(value) : nullptr;
}

const EncodableList* ListArg(const EncodableMap& args, const char* key) {
  const EncodableValue* value = Arg(args, key);
  return value ? std::get_if<EncodableList>(value) : nullptr;
}

// --- text escaping -----------------------------------------------------------------

std::wstring XmlEscape(const std::wstring& text) {
  std::wstring out;
  out.reserve(text.size());
  for (wchar_t c : text) {
    switch (c) {
      case L'&': out += L"&amp;"; break;
      case L'<': out += L"&lt;"; break;
      case L'>': out += L"&gt;"; break;
      case L'"': out += L"&quot;"; break;
      case L'\'': out += L"&apos;"; break;
      default: out += c;
    }
  }
  return out;
}

std::string JsonString(const std::string& text) {
  std::string out = "\"";
  for (unsigned char c : text) {
    switch (c) {
      case '"': out += "\\\""; break;
      case '\\': out += "\\\\"; break;
      case '\n': out += "\\n"; break;
      case '\r': out += "\\r"; break;
      case '\t': out += "\\t"; break;
      default:
        if (c < 0x20) {
          char buffer[8];
          snprintf(buffer, sizeof(buffer), "\\u%04x", static_cast<unsigned>(c));
          out += buffer;
        } else {
          out += static_cast<char>(c);
        }
    }
  }
  return out + "\"";
}

// The event a click reports, carried as the toast's launch / action arguments.
std::string EventJson(const char* type, int64_t id, const std::string& action, const std::string& payload) {
  std::string json = std::string("{\"type\":\"") + type + "\",\"id\":" + std::to_string(id);
  if (!action.empty()) json += ",\"actionId\":" + JsonString(action);
  if (!payload.empty()) json += ",\"payload\":" + JsonString(payload);
  return json + "}";
}

std::wstring FileUri(const std::string& path) {
  std::wstring wide = Widen(path);
  for (wchar_t& c : wide) {
    if (c == L'\\') c = L'/';
  }
  return L"file:///" + wide;
}

// --- toast XML ------------------------------------------------------------------------

std::wstring BuildXml(const EncodableMap& r) {
  const int64_t id = Int(r, "id", 0);
  const std::string payload = Str(r, "payload");
  std::wstring scenario;
  const std::string category = Str(r, "category");
  if (category == "alarm") scenario = L"alarm";
  else if (category == "call") scenario = L"incomingCall";
  else if (category == "reminder") scenario = L"reminder";
  else if (Str(r, "interruption") == "critical") scenario = L"urgent";

  std::wstring body = Widen(Str(r, "body"));
  if (const EncodableList* lines = ListArg(r, "lines")) {
    for (const EncodableValue& line : *lines) {
      if (const std::string* text = std::get_if<std::string>(&line)) body += (body.empty() ? L"" : L"\n") + Widen(*text);
    }
  }

  std::wstring out = L"<toast launch=\"" + XmlEscape(Widen(EventJson("tap", id, "", payload))) + L"\"";
  if (!scenario.empty()) out += L" scenario=\"" + scenario + L"\"";
  if (Bool(r, "ongoing") || Bool(r, "fullScreen")) out += L" duration=\"long\"";
  out += L"><visual><binding template=\"ToastGeneric\">";
  out += L"<text>" + XmlEscape(Widen(Str(r, "title"))) + L"</text>";
  if (!body.empty()) out += L"<text>" + XmlEscape(body) + L"</text>";
  if (!Str(r, "subtitle").empty()) out += L"<text placement=\"attribution\">" + XmlEscape(Widen(Str(r, "subtitle"))) + L"</text>";
  if (!Str(r, "image").empty()) out += L"<image placement=\"hero\" src=\"" + XmlEscape(FileUri(Str(r, "image"))) + L"\"/>";
  if (!Str(r, "largeIcon").empty()) out += L"<image placement=\"appLogoOverride\" hint-crop=\"circle\" src=\"" + XmlEscape(FileUri(Str(r, "largeIcon"))) + L"\"/>";
  // Bound to NotificationData so later updates change the bar in place.
  if (MapArg(r, "progress") != nullptr) out += L"<progress value=\"{progressValue}\" status=\"{progressStatus}\" valueStringOverride=\"{progressText}\"/>";
  out += L"</binding></visual>";

  if (const EncodableList* actions = ListArg(r, "actions")) {
    std::wstring inputs;
    std::wstring buttons;
    for (const EncodableValue& raw : *actions) {
      const EncodableMap* action = std::get_if<EncodableMap>(&raw);
      if (action == nullptr) continue;
      const std::string action_id = Str(*action, "id");
      const bool input = Bool(*action, "input");
      const std::string type = input ? "reply" : "action";
      if (input) inputs += L"<input id=\"u_input\" type=\"text\" placeHolderContent=\"" + XmlEscape(Widen(Str(*action, "inputPlaceholder"))) + L"\"/>";
      buttons += L"<action content=\"" + XmlEscape(Widen(Str(*action, "title"))) + L"\" arguments=\"" + XmlEscape(Widen(EventJson(type.c_str(), id, action_id, payload))) +
                 L"\" activationType=\"" + (Bool(*action, "foreground") ? L"foreground" : L"background") + L"\"" + (input ? L" hint-inputId=\"u_input\"" : L"") + L"/>";
    }
    if (!buttons.empty()) out += L"<actions>" + inputs + buttons + L"</actions>";
  }

  if (Bool(r, "silent")) {
    out += L"<audio silent=\"true\"/>";
  } else if (!Str(r, "sound").empty()) {
    out += L"<audio src=\"" + XmlEscape(Widen(Str(r, "sound"))) + L"\"/>";
  }
  return out + L"</toast>";
}

xml::XmlDocument Document(const EncodableMap& r) {
  xml::XmlDocument doc;
  doc.LoadXml(winrt::hstring(BuildXml(r)));
  return doc;
}

toast::NotificationData ProgressData(const EncodableMap& progress, uint32_t sequence) {
  toast::NotificationData data;
  const int64_t max = Int(progress, "max", 100);
  const int64_t value = Int(progress, "value", 0);
  const bool indeterminate = Bool(progress, "indeterminate");
  const double fraction = max > 0 ? static_cast<double>(value) / static_cast<double>(max) : 0;
  data.Values().Insert(L"progressValue", indeterminate ? L"indeterminate" : winrt::to_hstring(fraction));
  data.Values().Insert(L"progressStatus", winrt::hstring(Widen(Str(progress, "label"))));
  data.Values().Insert(L"progressText", indeterminate ? L"" : winrt::hstring(std::to_wstring(value * 100 / (max > 0 ? max : 1)) + L"%"));
  data.SequenceNumber(sequence);
  return data;
}

std::wstring FirstText(const xml::XmlDocument& doc, uint32_t index) {
  try {
    const xml::XmlNodeList texts = doc.GetElementsByTagName(L"text");
    return index < texts.Size() ? std::wstring(texts.Item(index).InnerText()) : std::wstring();
  } catch (...) {
    return std::wstring();
  }
}

// --- taskbar badge ---------------------------------------------------------------------

HICON BadgeIcon(int count) {
  constexpr int kSize = 32;
  BITMAPINFO info = {};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = kSize;
  info.bmiHeader.biHeight = -kSize;
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  info.bmiHeader.biCompression = BI_RGB;
  void* bits = nullptr;
  HDC screen = GetDC(nullptr);
  HBITMAP color = CreateDIBSection(screen, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
  HDC dc = CreateCompatibleDC(screen);
  ReleaseDC(nullptr, screen);
  if (color == nullptr || bits == nullptr) {
    if (color != nullptr) DeleteObject(color);
    DeleteDC(dc);
    return nullptr;
  }
  auto* pixels = static_cast<uint32_t*>(bits);
  auto inside = [](int x, int y) {
    const double dx = x + 0.5 - kSize / 2.0;
    const double dy = y + 0.5 - kSize / 2.0;
    return dx * dx + dy * dy <= (kSize / 2.0 - 0.5) * (kSize / 2.0 - 0.5);
  };
  for (int y = 0; y < kSize; y++) {
    for (int x = 0; x < kSize; x++) pixels[y * kSize + x] = inside(x, y) ? 0xFFE53935u : 0u;
  }
  HGDIOBJ old_bitmap = SelectObject(dc, color);
  HFONT font = CreateFontW(count > 99 ? -12 : -18, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, DEFAULT_PITCH, L"Segoe UI");
  HGDIOBJ old_font = SelectObject(dc, font);
  SetBkMode(dc, TRANSPARENT);
  SetTextColor(dc, RGB(255, 255, 255));
  RECT rect = {0, 0, kSize, kSize};
  const std::wstring label = count > 99 ? L"99+" : std::to_wstring(count);
  DrawTextW(dc, label.c_str(), -1, &rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
  SelectObject(dc, old_font);
  SelectObject(dc, old_bitmap);
  DeleteObject(font);
  DeleteDC(dc);
  // GDI clears the alpha byte where it draws text: make the whole disc opaque again.
  for (int y = 0; y < kSize; y++) {
    for (int x = 0; x < kSize; x++) {
      if (inside(x, y)) pixels[y * kSize + x] |= 0xFF000000u;
    }
  }
  std::vector<uint8_t> mask_bits(kSize * kSize / 8, 0);
  HBITMAP mask = CreateBitmap(kSize, kSize, 1, 1, mask_bits.data());
  ICONINFO icon_info = {TRUE, 0, 0, mask, color};
  HICON icon = CreateIconIndirect(&icon_info);
  DeleteObject(mask);
  DeleteObject(color);
  return icon;
}

bool SetBadge(int count) {
  HWND window = static_cast<HWND>(platform::OwnerWindow());
  if (window == nullptr) return false;
  ComPtr<ITaskbarList3> taskbar;
  if (FAILED(CoCreateInstance(CLSID_TaskbarList, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&taskbar))) || FAILED(taskbar->HrInit())) return false;
  if (count <= 0) return SUCCEEDED(taskbar->SetOverlayIcon(window, nullptr, L""));
  HICON icon = BadgeIcon(count);
  if (icon == nullptr) return false;
  const std::wstring description = std::to_wstring(count);
  const HRESULT hr = taskbar->SetOverlayIcon(window, icon, description.c_str());
  DestroyIcon(icon);
  return SUCCEEDED(hr);
}

// --- COM activator: Windows calls it when a toast (or its button) is clicked --------------

void OnActivated(const std::string& arguments, const std::string& input);

class ToastActivator : public INotificationActivationCallback {
 public:
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** out) override {
    if (out == nullptr) return E_POINTER;
    if (iid == IID_IUnknown || iid == __uuidof(INotificationActivationCallback)) {
      *out = static_cast<INotificationActivationCallback*>(this);
      AddRef();
      return S_OK;
    }
    *out = nullptr;
    return E_NOINTERFACE;
  }
  ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&refs_); }
  ULONG STDMETHODCALLTYPE Release() override {
    const ULONG left = InterlockedDecrement(&refs_);
    if (left == 0) delete this;
    return left;
  }
  HRESULT STDMETHODCALLTYPE Activate(LPCWSTR, LPCWSTR invoked, const NOTIFICATION_USER_INPUT_DATA* data, ULONG count) override {
    std::string input;
    for (ULONG i = 0; i < count; i++) {
      if (data[i].Key != nullptr && std::wstring(data[i].Key) == L"u_input" && data[i].Value != nullptr) input = Narrow(data[i].Value);
    }
    const std::string arguments = invoked != nullptr ? Narrow(invoked) : std::string();
    platform::Post([arguments, input]() { OnActivated(arguments, input); });
    return S_OK;
  }

 private:
  virtual ~ToastActivator() = default;
  LONG refs_ = 1;
};

class ActivatorFactory : public IClassFactory {
 public:
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** out) override {
    if (out == nullptr) return E_POINTER;
    if (iid == IID_IUnknown || iid == IID_IClassFactory) {
      *out = static_cast<IClassFactory*>(this);
      return S_OK;
    }
    *out = nullptr;
    return E_NOINTERFACE;
  }
  // Lives for the whole process: reference counting is a no-op.
  ULONG STDMETHODCALLTYPE AddRef() override { return 2; }
  ULONG STDMETHODCALLTYPE Release() override { return 1; }
  HRESULT STDMETHODCALLTYPE CreateInstance(IUnknown* outer, REFIID iid, void** out) override {
    if (outer != nullptr) return CLASS_E_NOAGGREGATION;
    auto* activator = new ToastActivator();
    const HRESULT hr = activator->QueryInterface(iid, out);
    activator->Release();
    return hr;
  }
  HRESULT STDMETHODCALLTYPE LockServer(BOOL) override { return S_OK; }
};

ActivatorFactory g_factory;

// --- the handler ---------------------------------------------------------------------------

class Notify {
 public:
  explicit Notify(flutter::PluginRegistrarWindows* registrar) {
    const auto& codec = flutter::StandardMethodCodec::GetInstance();
    channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(registrar->messenger(), "u/notify", &codec);
    channel_->SetMethodCallHandler([this](const auto& call, auto result) { Handle(call, std::move(result)); });
    events_ = std::make_unique<flutter::EventChannel<EncodableValue>>(registrar->messenger(), "u/notify/events", &codec);
    events_->SetStreamHandler(std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
        [this](const EncodableValue*, std::unique_ptr<Sink>&& sink) -> StreamError {
          sink_ = std::move(sink);
          for (const EncodableValue& event : queued_) sink_->Success(event);
          queued_.clear();
          return nullptr;
        },
        [this](const EncodableValue*) -> StreamError {
          sink_.reset();
          return nullptr;
        }));
  }

  static Notify*& Instance() {
    static Notify* instance = nullptr;
    return instance;
  }

  void Emit(EncodableMap event) {
    const EncodableValue value(event);
    if (!sink_ && launch_event_.IsNull()) launch_event_ = value;
    if (sink_) {
      sink_->Success(value);
    } else {
      queued_.push_back(value);
    }
  }

 private:
  static bool IsPackaged() {
    UINT32 length = 0;
    return GetCurrentPackageFullName(&length, nullptr) != APPMODEL_ERROR_NO_PACKAGE;
  }

  void Init(const EncodableMap& args) {
    if (notifier_) return;
    packaged_ = IsPackaged();
    aumid_ = Widen(Str(args, "appId"));
    if (!packaged_) {
      // Unpackaged apps need an app id, a Start-menu shortcut carrying it and a COM activator.
      SetCurrentProcessExplicitAppUserModelID(aumid_.c_str());
      const std::wstring guid_text = L"{" + Widen(Str(args, "guid")) + L"}";
      GUID guid = {};
      if (SUCCEEDED(CLSIDFromString(guid_text.c_str(), &guid))) {
        EnsureShortcut(Widen(Str(args, "appName")), guid, Widen(Str(args, "iconPath")));
        RegisterActivator(guid_text, guid);
      }
    }
    try {
      notifier_ = packaged_ ? toast::ToastNotificationManager::CreateToastNotifier() : toast::ToastNotificationManager::CreateToastNotifier(winrt::hstring(aumid_));
    } catch (...) {
      notifier_ = nullptr;
    }
  }

  void EnsureShortcut(std::wstring name, const GUID& guid, const std::wstring& icon) {
    for (wchar_t& c : name) {
      if (wcschr(L"\\/:*?\"<>|", c) != nullptr) c = L'_';
    }
    if (name.empty()) name = aumid_;
    PWSTR programs = nullptr;
    if (FAILED(SHGetKnownFolderPath(FOLDERID_Programs, 0, nullptr, &programs))) return;
    const std::wstring path = std::wstring(programs) + L"\\" + name + L".lnk";
    CoTaskMemFree(programs);
    wchar_t exe[MAX_PATH] = {};
    GetModuleFileNameW(nullptr, exe, MAX_PATH);
    ComPtr<IShellLinkW> link;
    if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&link)))) return;
    link->SetPath(exe);
    link->SetArguments(L"");
    if (!icon.empty()) link->SetIconLocation(icon.c_str(), 0);
    ComPtr<IPropertyStore> store;
    if (FAILED(link.As(&store))) return;
    PROPVARIANT value;
    if (SUCCEEDED(InitPropVariantFromString(aumid_.c_str(), &value))) {
      store->SetValue(PKEY_AppUserModel_ID, value);
      PropVariantClear(&value);
    }
    if (SUCCEEDED(InitPropVariantFromCLSID(guid, &value))) {
      store->SetValue(PKEY_AppUserModel_ToastActivatorCLSID, value);
      PropVariantClear(&value);
    }
    store->Commit();
    ComPtr<IPersistFile> file;
    if (SUCCEEDED(link.As(&file))) file->Save(path.c_str(), TRUE);
  }

  void RegisterActivator(const std::wstring& guid_text, const GUID& guid) {
    wchar_t exe[MAX_PATH] = {};
    GetModuleFileNameW(nullptr, exe, MAX_PATH);
    const std::wstring key = L"Software\\Classes\\CLSID\\" + guid_text + L"\\LocalServer32";
    const std::wstring value = L"\"" + std::wstring(exe) + L"\"";
    RegSetKeyValueW(HKEY_CURRENT_USER, key.c_str(), nullptr, REG_SZ, value.c_str(), static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t)));
    CoRegisterClassObject(guid, &g_factory, CLSCTX_LOCAL_SERVER, REGCLS_MULTIPLEUSE, &cookie_);
  }

  toast::ToastNotificationHistory History() { return toast::ToastNotificationManager::History(); }

  bool Show(const EncodableMap& r) {
    if (!notifier_) return false;
    const int64_t id = Int(r, "id", 0);
    const winrt::hstring tag(std::to_wstring(id));
    const winrt::hstring group(Widen(Str(r, "group").empty() ? "u" : Str(r, "group")));
    const EncodableMap* progress = MapArg(r, "progress");
    if (progress != nullptr && progress_ids_.count(id) > 0) {
      // Same progress notification: update the bar in place instead of popping a new toast.
      if (notifier_.Update(ProgressData(*progress, ++sequence_), tag, group) == toast::NotificationUpdateResult::Succeeded) return true;
    }
    toast::ToastNotification notification(Document(r));
    notification.Tag(tag);
    notification.Group(group);
    if (progress != nullptr) {
      notification.Data(ProgressData(*progress, ++sequence_));
      progress_ids_.insert(id);
    }
    const int64_t timeout = Int(r, "timeoutMs", 0);
    if (timeout > 0) notification.ExpirationTime(winrt::clock::now() + std::chrono::milliseconds(timeout));
    const std::string payload = Str(r, "payload");
    notification.Dismissed([id, payload](toast::ToastNotification const&, toast::ToastDismissedEventArgs const& args) {
      if (args.Reason() != toast::ToastDismissalReason::UserCanceled) return;
      const std::string json = EventJson("dismiss", id, "", payload);
      platform::Post([json]() { OnActivated(json, ""); });
    });
    notifier_.Show(notification);
    return true;
  }

  void RemoveScheduled(const winrt::hstring& tag) {
    for (const toast::ScheduledToastNotification& scheduled : notifier_.GetScheduledToastNotifications()) {
      if (tag.empty() || scheduled.Tag() == tag) notifier_.RemoveFromSchedule(scheduled);
    }
  }

  bool Schedule(const EncodableMap& args) {
    const EncodableMap* request = MapArg(args, "request");
    const EncodableList* times = ListArg(args, "times");
    if (!notifier_ || request == nullptr || times == nullptr) return false;
    const int64_t id = Int(*request, "id", 0);
    const winrt::hstring tag(std::to_wstring(id));
    const winrt::hstring group(Widen(Str(*request, "group").empty() ? "u" : Str(*request, "group")));
    RemoveScheduled(tag);
    uint32_t index = 0;
    for (const EncodableValue& raw : *times) {
      int64_t ms = 0;
      if (const int64_t* l = std::get_if<int64_t>(&raw)) ms = *l;
      else if (const int32_t* i = std::get_if<int32_t>(&raw)) ms = *i;
      const auto when = winrt::clock::from_sys(std::chrono::system_clock::time_point(std::chrono::milliseconds(ms)));
      toast::ScheduledToastNotification scheduled(Document(*request), when);
      scheduled.Tag(tag);
      scheduled.Group(group);
      // Ids are limited to 16 characters.
      scheduled.Id(winrt::hstring(std::wstring(tag).substr(0, 12) + L"_" + std::to_wstring(index++)));
      notifier_.AddToSchedule(scheduled);
    }
    return true;
  }

  void Cancel(int64_t id) {
    const winrt::hstring tag(std::to_wstring(id));
    if (notifier_) RemoveScheduled(tag);
    try {
      for (const toast::ToastNotification& shown : History().GetHistory(winrt::hstring(aumid_))) {
        if (shown.Tag() == tag) History().Remove(tag, shown.Group(), winrt::hstring(aumid_));
      }
    } catch (...) {
    }
    progress_ids_.erase(id);
  }

  EncodableList Pending() {
    std::map<std::wstring, EncodableMap> byTag;
    for (const toast::ScheduledToastNotification& scheduled : notifier_.GetScheduledToastNotifications()) {
      const std::wstring tag(scheduled.Tag());
      const int64_t next = std::chrono::duration_cast<std::chrono::milliseconds>(winrt::clock::to_sys(scheduled.DeliveryTime()).time_since_epoch()).count();
      auto it = byTag.find(tag);
      if (it != byTag.end()) {
        const int64_t* existing = std::get_if<int64_t>(&it->second[EncodableValue("next")]);
        if (existing != nullptr && *existing <= next) continue;
      }
      byTag[tag] = EncodableMap{
          {EncodableValue("id"), EncodableValue(static_cast<int64_t>(_wtoi64(tag.c_str())))},
          {EncodableValue("title"), EncodableValue(Narrow(FirstText(scheduled.Content(), 0)))},
          {EncodableValue("body"), EncodableValue(Narrow(FirstText(scheduled.Content(), 1)))},
          {EncodableValue("next"), EncodableValue(next)},
      };
    }
    EncodableList out;
    for (auto& entry : byTag) out.push_back(EncodableValue(entry.second));
    return out;
  }

  EncodableList Active() {
    EncodableList out;
    for (const toast::ToastNotification& shown : History().GetHistory(winrt::hstring(aumid_))) {
      out.push_back(EncodableValue(EncodableMap{
          {EncodableValue("id"), EncodableValue(static_cast<int64_t>(_wtoi64(shown.Tag().c_str())))},
          {EncodableValue("title"), EncodableValue(Narrow(FirstText(shown.Content(), 0)))},
          {EncodableValue("body"), EncodableValue(Narrow(FirstText(shown.Content(), 1)))},
          {EncodableValue("group"), EncodableValue(Narrow(std::wstring(shown.Group())))},
      }));
    }
    return out;
  }

  EncodableMap Permission() {
    std::string status = "unsupported";
    if (notifier_) {
      try {
        status = notifier_.Setting() == toast::NotificationSetting::Enabled ? "granted" : "denied";
      } catch (...) {
        status = "granted";
      }
    }
    return EncodableMap{{EncodableValue("status"), EncodableValue(status)}, {EncodableValue("exactAlarms"), EncodableValue(true)}};
  }

  void Handle(const flutter::MethodCall<EncodableValue>& call, std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    static const EncodableMap kEmpty;
    const EncodableMap* maybe = std::get_if<EncodableMap>(call.arguments());
    const EncodableMap& args = maybe ? *maybe : kEmpty;
    const std::string& method = call.method_name();
    try {
      if (method == "init") {
        Init(args);
        result->Success();
      } else if (method == "permission" || method == "requestPermission") {
        result->Success(EncodableValue(Permission()));
      } else if (method == "show") {
        result->Success(EncodableValue(Show(args)));
      } else if (method == "schedule") {
        result->Success(EncodableValue(Schedule(args)));
      } else if (method == "cancel") {
        Cancel(Int(args, "id", 0));
        result->Success();
      } else if (method == "cancelAll") {
        if (notifier_) RemoveScheduled(winrt::hstring());
        History().Clear(winrt::hstring(aumid_));
        progress_ids_.clear();
        result->Success();
      } else if (method == "cancelGroup") {
        History().RemoveGroup(winrt::hstring(Widen(Str(args, "group"))), winrt::hstring(aumid_));
        result->Success();
      } else if (method == "pending") {
        result->Success(EncodableValue(notifier_ ? Pending() : EncodableList()));
      } else if (method == "active") {
        result->Success(EncodableValue(notifier_ ? Active() : EncodableList()));
      } else if (method == "setBadge") {
        result->Success(EncodableValue(SetBadge(static_cast<int>(Int(args, "count", 0)))));
      } else if (method == "launchEvent") {
        result->Success(launch_event_);
      } else if (method == "channels") {
        result->Success(EncodableValue(EncodableList()));
      } else if (method == "createChannel" || method == "deleteChannel" || method == "createChannelGroup") {
        result->Success();
      } else {
        result->NotImplemented();
      }
    } catch (winrt::hresult_error const& e) {
      result->Error("u_notify", Narrow(std::wstring(e.message())));
    } catch (...) {
      result->Error("u_notify", "Notification call failed");
    }
  }

  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> events_;
  std::unique_ptr<Sink> sink_;
  EncodableList queued_;
  EncodableValue launch_event_;
  toast::ToastNotifier notifier_{nullptr};
  std::wstring aumid_;
  bool packaged_ = false;
  DWORD cookie_ = 0;
  uint32_t sequence_ = 0;
  std::set<int64_t> progress_ids_;
};

void OnActivated(const std::string& arguments, const std::string& input) {
  Notify* notify = Notify::Instance();
  if (notify == nullptr || arguments.empty()) return;
  EncodableMap event{{EncodableValue("json"), EncodableValue(arguments)}};
  if (!input.empty()) event[EncodableValue("input")] = EncodableValue(input);
  notify->Emit(event);
}

}  // namespace

void RegisterNotification(flutter::PluginRegistrarWindows* registrar) {
  if (Notify::Instance() != nullptr) return;
  // Kept alive for the app's lifetime; COM and WinRT callbacks reach it through Instance().
  Notify::Instance() = new Notify(registrar);
}

}  // namespace u
