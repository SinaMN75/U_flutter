#include "u_launch.h"

#include <windows.h>
#include <mapi.h>
#include <shellapi.h>
#include <shlwapi.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "../common/u_platform.h"

namespace u {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using platform::Narrow;
using platform::Widen;

const EncodableValue* Arg(const EncodableMap& args, const char* key) {
  const auto it = args.find(EncodableValue(key));
  return it == args.end() ? nullptr : &it->second;
}

std::string StringArg(const EncodableMap& args, const char* key) {
  const EncodableValue* value = Arg(args, key);
  const std::string* text = value ? std::get_if<std::string>(value) : nullptr;
  return text ? *text : std::string();
}

bool BoolArg(const EncodableMap& args, const char* key) {
  const EncodableValue* value = Arg(args, key);
  const bool* flag = value ? std::get_if<bool>(value) : nullptr;
  return flag && *flag;
}

std::vector<std::string> ListArg(const EncodableMap& args, const char* key) {
  std::vector<std::string> out;
  const EncodableValue* value = Arg(args, key);
  const EncodableList* list = value ? std::get_if<EncodableList>(value) : nullptr;
  if (list == nullptr) return out;
  for (const EncodableValue& item : *list) {
    if (const auto* text = std::get_if<std::string>(&item)) out.push_back(*text);
  }
  return out;
}

bool Open(const std::wstring& target) {
  const HINSTANCE result = ShellExecuteW(static_cast<HWND>(platform::OwnerWindow()), L"open", target.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
  return reinterpret_cast<INT_PTR>(result) > 32;
}

std::wstring SchemeOf(const std::wstring& url) {
  const size_t colon = url.find(L':');
  // "C:\..." is a drive letter, not a scheme.
  if (colon == std::wstring::npos || colon < 2) return std::wstring();
  return url.substr(0, colon);
}

bool HasProtocolHandler(const std::wstring& scheme) {
  if (scheme.empty()) return false;
  if (scheme == L"http" || scheme == L"https" || scheme == L"file" || scheme == L"mailto") return true;
  DWORD size = 0;
  return AssocQueryStringW(ASSOCF_IS_PROTOCOL, ASSOCSTR_COMMAND, scheme.c_str(), L"open", nullptr, &size) == S_FALSE;
}

std::wstring SettingsUri(const std::string& page) {
  static const std::map<std::string, std::wstring> pages = {
      {"notifications", L"ms-settings:notifications"},
      {"notificationChannel", L"ms-settings:notifications"},
      {"location", L"ms-settings:privacy-location"},
      {"wifi", L"ms-settings:network-wifi"},
      {"bluetooth", L"ms-settings:bluetooth"},
      {"battery", L"ms-settings:batterysaver"},
      {"display", L"ms-settings:display"},
      {"sound", L"ms-settings:sound"},
      {"dateTime", L"ms-settings:dateandtime"},
      {"language", L"ms-settings:regionlanguage"},
      {"security", L"windowsdefender:"},
      {"dataUsage", L"ms-settings:datausage"},
      {"accessibility", L"ms-settings:easeofaccess"},
      {"developer", L"ms-settings:developers"},
      {"storage", L"ms-settings:storagesense"},
      {"vpn", L"ms-settings:network-vpn"},
      {"airplaneMode", L"ms-settings:network-airplanemode"},
      {"defaultApps", L"ms-settings:defaultapps"},
  };
  const auto it = pages.find(page);
  return it == pages.end() ? L"ms-settings:appsfeatures" : it->second;
}

// Simple MAPI: the default mail client's compose window, attachments included.
// Returns true when a MAPI client took the message (sent or saved), false to fall back to mailto.
bool MapiCompose(const EncodableMap& args) {
  HMODULE mapi = LoadLibraryW(L"mapi32.dll");
  if (mapi == nullptr) return false;
  auto send = reinterpret_cast<LPMAPISENDMAILW>(GetProcAddress(mapi, "MAPISendMailW"));
  if (send == nullptr) {
    FreeLibrary(mapi);
    return false;
  }
  std::vector<std::wstring> storage;
  storage.reserve(64);
  auto keep = [&storage](const std::wstring& text) -> PWSTR {
    storage.push_back(text);
    return storage.back().data();
  };
  std::vector<MapiRecipDescW> recipients;
  auto add = [&](const char* key, ULONG kind) {
    for (const std::string& address : ListArg(args, key)) {
      MapiRecipDescW recipient = {};
      recipient.ulRecipClass = kind;
      recipient.lpszName = keep(Widen(address));
      recipient.lpszAddress = keep(L"SMTP:" + Widen(address));
      recipients.push_back(recipient);
    }
  };
  add("to", MAPI_TO);
  add("cc", MAPI_CC);
  add("bcc", MAPI_BCC);
  std::vector<MapiFileDescW> files;
  for (const std::string& path : ListArg(args, "attachments")) {
    std::wstring wide = Widen(path);
    for (wchar_t& c : wide) {
      if (c == L'/') c = L'\\';
    }
    MapiFileDescW file = {};
    file.nPosition = static_cast<ULONG>(-1);
    file.lpszPathName = keep(wide);
    files.push_back(file);
  }
  MapiMessageW message = {};
  const std::string subject = StringArg(args, "subject");
  const std::string body = StringArg(args, "body");
  message.lpszSubject = subject.empty() ? nullptr : keep(Widen(subject));
  message.lpszNoteText = body.empty() ? nullptr : keep(Widen(body));
  message.nRecipCount = static_cast<ULONG>(recipients.size());
  message.lpRecips = recipients.empty() ? nullptr : recipients.data();
  message.nFileCount = static_cast<ULONG>(files.size());
  message.lpFiles = files.empty() ? nullptr : files.data();
  const ULONG status = send(0, reinterpret_cast<ULONG_PTR>(platform::OwnerWindow()), &message, MAPI_DIALOG | MAPI_LOGON_UI, 0);
  FreeLibrary(mapi);
  return status == SUCCESS_SUCCESS || status == MAPI_USER_ABORT;
}

std::string LinkFromArguments() {
  for (const std::wstring& arg : platform::Arguments()) {
    const std::wstring scheme = SchemeOf(arg);
    if (!scheme.empty() && scheme != L"file" && GetFileAttributesW(arg.c_str()) == INVALID_FILE_ATTRIBUTES) return Narrow(arg);
  }
  return std::string();
}

class Launch {
 public:
  explicit Launch(flutter::PluginRegistrarWindows* registrar) {
    channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(registrar->messenger(), "u/launch", &flutter::StandardMethodCodec::GetInstance());
    channel_->SetMethodCallHandler([this](const auto& call, auto result) { Handle(call, std::move(result)); });
    events_ = std::make_unique<flutter::EventChannel<EncodableValue>>(registrar->messenger(), "u/launch/events", &flutter::StandardMethodCodec::GetInstance());
    events_->SetStreamHandler(std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
        [](const EncodableValue*, std::unique_ptr<flutter::EventSink<EncodableValue>>&&) -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
          // Windows starts a new process per link unless the app forwards it itself; nothing to stream.
          return nullptr;
        },
        [](const EncodableValue*) -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> { return nullptr; }));
    initial_link_ = LinkFromArguments();
  }

 private:
  void Handle(const flutter::MethodCall<EncodableValue>& call, std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    static const EncodableMap kEmpty;
    const EncodableMap* maybe = std::get_if<EncodableMap>(call.arguments());
    const EncodableMap& args = maybe ? *maybe : kEmpty;
    const std::string& method = call.method_name();
    if (method == "open") {
      result->Success(EncodableValue(Open(Widen(StringArg(args, "url")))));
    } else if (method == "canOpen") {
      result->Success(EncodableValue(HasProtocolHandler(SchemeOf(Widen(StringArg(args, "url"))))));
    } else if (method == "isInstalled") {
      std::wstring id = Widen(StringArg(args, "id"));
      const size_t colon = id.find(L':');
      if (colon != std::wstring::npos) id = id.substr(0, colon);
      result->Success(EncodableValue(HasProtocolHandler(id)));
    } else if (method == "openApp") {
      std::wstring id = Widen(StringArg(args, "id"));
      if (id.find(L':') == std::wstring::npos) id += L":";
      result->Success(EncodableValue(Open(id)));
    } else if (method == "openSettings") {
      result->Success(EncodableValue(Open(SettingsUri(StringArg(args, "page")))));
    } else if (method == "email") {
      // MAPI shows a modal compose window: run it off the platform thread.
      platform::SharedResult shared(std::move(result));
      const EncodableMap copy = args;
      platform::RunInBackground([shared, copy]() {
        const bool mapi = MapiCompose(copy);
        platform::Post([shared, copy, mapi]() {
          if (mapi) return shared->Success(EncodableValue("opened"));
          shared->Success(EncodableValue(Open(Widen(StringArg(copy, "mailto"))) ? "opened" : "unavailable"));
        });
      });
    } else if (method == "sms") {
      result->Success(EncodableValue(Open(Widen(StringArg(args, "url"))) ? "opened" : "unavailable"));
    } else if (method == "openStore") {
      const std::string id = StringArg(args, "appId");
      const std::string store = StringArg(args, "store");
      if (id.empty() || (store != "auto" && store != "microsoft")) return result->Success(EncodableValue(false));
      const std::wstring target = (BoolArg(args, "review") ? L"ms-windows-store://review/?ProductId=" : L"ms-windows-store://pdp/?ProductId=") + Widen(id);
      result->Success(EncodableValue(Open(target)));
    } else if (method == "initialLink") {
      result->Success(initial_link_.empty() ? EncodableValue() : EncodableValue(initial_link_));
    } else if (method == "requestReview" || method == "closeInApp") {
      result->Success(EncodableValue(false));
    } else {
      result->NotImplemented();
    }
  }

  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> events_;
  std::string initial_link_;
};

}  // namespace

void RegisterLaunch(flutter::PluginRegistrarWindows* registrar) {
  platform::Initialize();
  // Kept alive for the app's lifetime, like the other feature handlers.
  static Launch* launch = new Launch(registrar);
  (void)launch;
}

}  // namespace u
