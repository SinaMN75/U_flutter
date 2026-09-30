// windows.h's min/max macros break the C++/WinRT headers.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shobjidl_core.h>

#include <winrt/Windows.ApplicationModel.DataTransfer.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Storage.h>

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <vector>

#include "../common/u_platform.h"
#include "u_launch.h"

namespace u {

namespace {

namespace dt = winrt::Windows::ApplicationModel::DataTransfer;
namespace storage = winrt::Windows::Storage;
using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using platform::Narrow;
using platform::Widen;

std::string StringArg(const EncodableMap& args, const char* key) {
  const auto it = args.find(EncodableValue(key));
  if (it == args.end()) return std::string();
  const std::string* text = std::get_if<std::string>(&it->second);
  return text ? *text : std::string();
}

std::vector<std::wstring> FilePaths(const EncodableMap& args) {
  std::vector<std::wstring> out;
  const auto it = args.find(EncodableValue("files"));
  if (it == args.end()) return out;
  const EncodableList* list = std::get_if<EncodableList>(&it->second);
  if (list == nullptr) return out;
  for (const EncodableValue& item : *list) {
    const EncodableMap* file = std::get_if<EncodableMap>(&item);
    if (file == nullptr) continue;
    std::wstring path = Widen(StringArg(*file, "path"));
    for (wchar_t& c : path) {
      if (c == L'/') c = L'\\';
    }
    if (!path.empty()) out.push_back(path);
  }
  return out;
}

EncodableMap Status(const char* status) { return EncodableMap{{EncodableValue("status"), EncodableValue(status)}}; }

class Share {
 public:
  explicit Share(flutter::PluginRegistrarWindows* registrar) {
    channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(registrar->messenger(), "u/share", &flutter::StandardMethodCodec::GetInstance());
    channel_->SetMethodCallHandler([this](const auto& call, auto result) { Handle(call, std::move(result)); });
    events_ = std::make_unique<flutter::EventChannel<EncodableValue>>(registrar->messenger(), "u/share/received", &flutter::StandardMethodCodec::GetInstance());
    events_->SetStreamHandler(std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
        [](const EncodableValue*, std::unique_ptr<flutter::EventSink<EncodableValue>>&&) -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> { return nullptr; },
        [](const EncodableValue*) -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> { return nullptr; }));
    // "Open with" / drag-onto-exe: existing files on the command line.
    for (const std::wstring& arg : platform::Arguments()) {
      const DWORD attributes = GetFileAttributesW(arg.c_str());
      if (attributes != INVALID_FILE_ATTRIBUTES && !(attributes & FILE_ATTRIBUTE_DIRECTORY)) {
        const size_t slash = arg.find_last_of(L"\\/");
        initial_files_.push_back(EncodableValue(EncodableMap{
            {EncodableValue("path"), EncodableValue(Narrow(arg))},
            {EncodableValue("name"), EncodableValue(Narrow(slash == std::wstring::npos ? arg : arg.substr(slash + 1)))},
        }));
      }
    }
  }

 private:
  void Handle(const flutter::MethodCall<EncodableValue>& call, std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
    static const EncodableMap kEmpty;
    const EncodableMap* maybe = std::get_if<EncodableMap>(call.arguments());
    const EncodableMap& args = maybe ? *maybe : kEmpty;
    const std::string& method = call.method_name();
    if (method == "share") {
      ShareSheet(args, platform::SharedResult(std::move(result)));
    } else if (method == "initialShare") {
      if (initial_files_.empty()) return result->Success(EncodableValue());
      result->Success(EncodableValue(EncodableMap{{EncodableValue("files"), EncodableValue(initial_files_)}}));
    } else if (method == "shareTo" || method == "canShareTo") {
      // Windows has no per-app share targets; Dart falls back to the share sheet.
      result->Success(method == "canShareTo" ? EncodableValue(false) : EncodableValue(Status("unavailable")));
    } else {
      result->NotImplemented();
    }
  }

  void ShareSheet(const EncodableMap& args, platform::SharedResult result) {
    std::string text = StringArg(args, "text");
    const std::string url = StringArg(args, "url");
    std::string title = StringArg(args, "title");
    if (title.empty()) title = StringArg(args, "subject");
    const std::vector<std::wstring> paths = FilePaths(args);
    // StorageFile lookups are async: resolve them on a worker thread, then show the UI on ours.
    platform::RunInBackground([this, text, url, title, paths, result]() {
      auto items = std::make_shared<std::vector<storage::IStorageItem>>();
      for (const std::wstring& path : paths) {
        try {
          items->push_back(storage::StorageFile::GetFileFromPathAsync(path).get());
        } catch (...) {
        }
      }
      platform::Post([this, text, url, title, items, result]() { Show(text, url, title, items, result); });
    });
  }

  void Show(const std::string& text, const std::string& url, const std::string& title, std::shared_ptr<std::vector<storage::IStorageItem>> items, platform::SharedResult result) {
    HWND window = static_cast<HWND>(platform::OwnerWindow());
    if (window == nullptr) return result->Success(EncodableValue(Status("unavailable")));
    try {
      auto interop = winrt::get_activation_factory<dt::DataTransferManager, IDataTransferManagerInterop>();
      dt::DataTransferManager manager{nullptr};
      winrt::check_hresult(interop->GetForWindow(window, winrt::guid_of<dt::IDataTransferManager>(), winrt::put_abi(manager)));
      if (manager_) manager_.DataRequested(token_);
      manager_ = manager;
      const std::wstring wtitle = Widen(title.empty() ? (text.empty() ? std::string("Share") : text.substr(0, 60)) : title);
      const std::wstring wtext = Widen(text);
      const std::wstring wurl = Widen(url);
      token_ = manager.DataRequested([wtitle, wtext, wurl, items](dt::DataTransferManager const&, dt::DataRequestedEventArgs const& event) {
        try {
          dt::DataPackage data = event.Request().Data();
          // Without a title Windows reports "nothing to share".
          data.Properties().Title(winrt::hstring(wtitle));
          if (!wtext.empty()) data.SetText(winrt::hstring(wtext));
          if (!wurl.empty()) data.SetWebLink(winrt::Windows::Foundation::Uri(winrt::hstring(wurl)));
          if (!items->empty()) data.SetStorageItems(winrt::single_threaded_vector<storage::IStorageItem>(std::vector<storage::IStorageItem>(*items)));
        } catch (...) {
        }
      });
      winrt::check_hresult(interop->ShowShareUIForWindow(window));
      result->Success(EncodableValue(Status("shown")));
    } catch (...) {
      result->Success(EncodableValue(Status("unavailable")));
    }
  }

  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
  std::unique_ptr<flutter::EventChannel<EncodableValue>> events_;
  EncodableList initial_files_;
  dt::DataTransferManager manager_{nullptr};
  winrt::event_token token_{};
};

}  // namespace

void RegisterShare(flutter::PluginRegistrarWindows* registrar) {
  static Share* share = new Share(registrar);
  (void)share;
}

}  // namespace u
