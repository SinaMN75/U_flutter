#include "u_files.h"

// windows.h must precede the COM / shell headers.
#include <windows.h>

#include <bits.h>
#include <bits5_0.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wincred.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <vector>

namespace u {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

std::wstring Widen(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  const int size = MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), nullptr, 0);
  std::wstring out(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), out.data(), size);
  return out;
}

std::string Narrow(const std::wstring& wide) {
  if (wide.empty()) return std::string();
  const int size = WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()), nullptr, 0, nullptr, nullptr);
  std::string out(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()), out.data(), size, nullptr, nullptr);
  return out;
}

// Dart joins storage paths with "/"; several shell APIs only accept "\".
std::wstring WindowsPath(const std::string& path) {
  std::wstring wide = Widen(path);
  for (wchar_t& c : wide) {
    if (c == L'/') c = L'\\';
  }
  return wide;
}

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

// ---------------------------------------------------------------------------
// Secrets
// ---------------------------------------------------------------------------

std::wstring CredentialTarget(const std::string& alias) { return L"u.files/" + Widen(alias); }

bool StoreSecret(const std::string& alias, const std::vector<uint8_t>& secret) {
  std::wstring target = CredentialTarget(alias);
  CREDENTIALW credential = {};
  credential.Type = CRED_TYPE_GENERIC;
  credential.TargetName = target.data();
  credential.CredentialBlobSize = static_cast<DWORD>(secret.size());
  credential.CredentialBlob = const_cast<LPBYTE>(secret.data());
  credential.Persist = CRED_PERSIST_LOCAL_MACHINE;
  return CredWriteW(&credential, 0) == TRUE;
}

// ---------------------------------------------------------------------------
// BITS
// ---------------------------------------------------------------------------

const wchar_t kJobPrefix[] = L"u:";

IBackgroundCopyManager* BitsManager() {
  IBackgroundCopyManager* manager = nullptr;
  CoCreateInstance(__uuidof(BackgroundCopyManager), nullptr, CLSCTX_LOCAL_SERVER, __uuidof(IBackgroundCopyManager),
                   reinterpret_cast<void**>(&manager));
  return manager;
}

// Visits every BITS job this app created; the callback receives the Dart task id.
template <typename F>
void ForEachJob(IBackgroundCopyManager* manager, F callback) {
  IEnumBackgroundCopyJobs* jobs = nullptr;
  if (FAILED(manager->EnumJobs(0, &jobs))) return;
  IBackgroundCopyJob* job = nullptr;
  while (jobs->Next(1, &job, nullptr) == S_OK) {
    LPWSTR name = nullptr;
    if (SUCCEEDED(job->GetDisplayName(&name)) && name && wcsncmp(name, kJobPrefix, 2) == 0) {
      callback(job, Narrow(std::wstring(name + 2)));
    }
    if (name) CoTaskMemFree(name);
    job->Release();
  }
  jobs->Release();
}

std::string JobLocalPath(IBackgroundCopyJob* job) {
  std::string path;
  IEnumBackgroundCopyFiles* files = nullptr;
  if (FAILED(job->EnumFiles(&files))) return path;
  IBackgroundCopyFile* file = nullptr;
  if (files->Next(1, &file, nullptr) == S_OK) {
    LPWSTR local = nullptr;
    if (SUCCEEDED(file->GetLocalName(&local)) && local) {
      path = Narrow(local);
      CoTaskMemFree(local);
    }
    file->Release();
  }
  files->Release();
  return path;
}

bool BitsEnqueue(const EncodableMap& args) {
  IBackgroundCopyManager* manager = BitsManager();
  if (!manager) return false;
  const std::wstring name = kJobPrefix + Widen(StringArg(args, "id"));
  GUID id;
  IBackgroundCopyJob* job = nullptr;
  bool ok = SUCCEEDED(manager->CreateJob(name.c_str(), BG_JOB_TYPE_DOWNLOAD, &id, &job));
  if (ok) {
    const std::wstring path = WindowsPath(StringArg(args, "path"));
    const size_t slash = path.find_last_of(L'\\');
    if (slash != std::wstring::npos) SHCreateDirectoryExW(nullptr, path.substr(0, slash).c_str(), nullptr);
    ok = SUCCEEDED(job->AddFile(Widen(StringArg(args, "url")).c_str(), path.c_str()));
    if (ok) {
      const EncodableValue* headers = Arg(args, "headers");
      const EncodableMap* map = headers ? std::get_if<EncodableMap>(headers) : nullptr;
      if (map && !map->empty()) {
        std::wstring block;
        for (const auto& entry : *map) {
          const std::string* key = std::get_if<std::string>(&entry.first);
          const std::string* value = std::get_if<std::string>(&entry.second);
          if (key && value) block += Widen(*key) + L": " + Widen(*value) + L"\r\n";
        }
        IBackgroundCopyJobHttpOptions* http = nullptr;
        if (SUCCEEDED(job->QueryInterface(__uuidof(IBackgroundCopyJobHttpOptions), reinterpret_cast<void**>(&http)))) {
          http->SetCustomHeaders(block.c_str());
          http->Release();
        }
      }
      if (BoolArg(args, "wifiOnly")) {
        IBackgroundCopyJob5* job5 = nullptr;
        if (SUCCEEDED(job->QueryInterface(__uuidof(IBackgroundCopyJob5), reinterpret_cast<void**>(&job5)))) {
          BITS_JOB_PROPERTY_VALUE value;
          value.Dword = BITS_COST_STATE_UNRESTRICTED;
          job5->SetProperty(BITS_JOB_PROPERTY_ID_COST_FLAGS, value);
          job5->Release();
        }
      }
      job->SetPriority(BG_JOB_PRIORITY_FOREGROUND);
      ok = SUCCEEDED(job->Resume());
    }
    if (!ok) job->Cancel();
    job->Release();
  }
  manager->Release();
  return ok;
}

void BitsCancel(const std::string& id) {
  IBackgroundCopyManager* manager = BitsManager();
  if (!manager) return;
  ForEachJob(manager, [&](IBackgroundCopyJob* job, const std::string& jobId) {
    if (jobId == id) job->Cancel();
  });
  manager->Release();
}

EncodableList BitsQuery() {
  EncodableList items;
  IBackgroundCopyManager* manager = BitsManager();
  if (!manager) return items;
  ForEachJob(manager, [&](IBackgroundCopyJob* job, const std::string& id) {
    BG_JOB_STATE state;
    BG_JOB_PROGRESS progress = {};
    if (FAILED(job->GetState(&state)) || FAILED(job->GetProgress(&progress))) return;
    const int64_t total = progress.BytesTotal == BG_SIZE_UNKNOWN ? -1 : static_cast<int64_t>(progress.BytesTotal);
    EncodableMap item;
    item[EncodableValue("id")] = EncodableValue(id);
    item[EncodableValue("received")] = EncodableValue(static_cast<int64_t>(progress.BytesTransferred));
    item[EncodableValue("total")] = EncodableValue(total);
    switch (state) {
      case BG_JOB_STATE_QUEUED:
      case BG_JOB_STATE_CONNECTING:
        item[EncodableValue("state")] = EncodableValue("queued");
        break;
      case BG_JOB_STATE_TRANSFERRING:
        item[EncodableValue("state")] = EncodableValue("running");
        break;
      case BG_JOB_STATE_SUSPENDED:
      case BG_JOB_STATE_TRANSIENT_ERROR:
        item[EncodableValue("state")] = EncodableValue("paused");
        break;
      case BG_JOB_STATE_TRANSFERRED: {
        // BITS keeps the data in a hidden temp file until the job is completed.
        const std::string path = JobLocalPath(job);
        job->Complete();
        item[EncodableValue("state")] = EncodableValue("completed");
        item[EncodableValue("path")] = EncodableValue(path);
        break;
      }
      case BG_JOB_STATE_ERROR: {
        std::string message = "BITS error";
        IBackgroundCopyError* error = nullptr;
        if (SUCCEEDED(job->GetError(&error))) {
          LPWSTR description = nullptr;
          if (SUCCEEDED(error->GetErrorDescription(LANGIDFROMLCID(GetThreadLocale()), &description)) && description) {
            message = Narrow(description);
            CoTaskMemFree(description);
          }
          error->Release();
        }
        job->Cancel();
        item[EncodableValue("state")] = EncodableValue("failed");
        item[EncodableValue("error")] = EncodableValue(message);
        break;
      }
      default:
        return;
    }
    items.push_back(EncodableValue(item));
  });
  manager->Release();
  return items;
}

}  // namespace

// static
void UFiles::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
  // Kept alive for the app's lifetime, like the other feature handlers.
  auto* files = new UFiles(registrar);
  (void)files;
}

UFiles::UFiles(flutter::PluginRegistrarWindows* registrar) : registrar_(registrar) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(registrar->messenger(), "u/files",
                                                                      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) { HandleMethodCall(call, std::move(result)); });
}

UFiles::~UFiles() {}

void UFiles::HandleMethodCall(const flutter::MethodCall<EncodableValue>& call,
                              std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  static const EncodableMap kEmpty;
  const EncodableMap* maybe = std::get_if<EncodableMap>(call.arguments());
  const EncodableMap& args = maybe ? *maybe : kEmpty;
  const std::string& method = call.method_name();
  // Flutter initialises COM on the platform thread; this is a no-op then.
  const HRESULT com = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  if (method == "freeSpace") {
    std::wstring path = WindowsPath(StringArg(args, "path"));
    ULARGE_INTEGER available;
    // Walk up to an existing directory: the target file usually does not exist yet.
    while (!path.empty() && !GetDiskFreeSpaceExW(path.c_str(), &available, nullptr, nullptr)) {
      const size_t slash = path.find_last_of(L'\\');
      path = slash == std::wstring::npos ? std::wstring() : path.substr(0, slash);
    }
    result->Success(path.empty() ? EncodableValue() : EncodableValue(static_cast<int64_t>(available.QuadPart)));
  } else if (method == "saveAs") {
    IFileSaveDialog* dialog = nullptr;
    EncodableValue saved;
    if (SUCCEEDED(CoCreateInstance(CLSID_FileSaveDialog, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dialog)))) {
      dialog->SetFileName(Widen(StringArg(args, "fileName")).c_str());
      HWND owner = registrar_->GetView() ? GetAncestor(registrar_->GetView()->GetNativeWindow(), GA_ROOT) : nullptr;
      if (SUCCEEDED(dialog->Show(owner))) {
        IShellItem* item = nullptr;
        if (SUCCEEDED(dialog->GetResult(&item))) {
          LPWSTR target = nullptr;
          if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &target)) && target) {
            if (CopyFileW(WindowsPath(StringArg(args, "sourcePath")).c_str(), target, FALSE)) saved = EncodableValue(Narrow(target));
            CoTaskMemFree(target);
          }
          item->Release();
        }
      }
      dialog->Release();
    }
    result->Success(saved);
  } else if (method == "open") {
    const HINSTANCE code = ShellExecuteW(nullptr, L"open", WindowsPath(StringArg(args, "path")).c_str(), nullptr, nullptr, SW_SHOWNORMAL);
    result->Success(EncodableValue(reinterpret_cast<INT_PTR>(code) > 32));
  } else if (method == "reveal") {
    PIDLIST_ABSOLUTE pidl = nullptr;
    bool ok = false;
    if (SUCCEEDED(SHParseDisplayName(WindowsPath(StringArg(args, "path")).c_str(), nullptr, &pidl, 0, nullptr))) {
      ok = SUCCEEDED(SHOpenFolderAndSelectItems(pidl, 0, nullptr, 0));
      CoTaskMemFree(pidl);
    }
    result->Success(EncodableValue(ok));
  } else if (method == "keepAwake") {
    SetThreadExecutionState(BoolArg(args, "enabled") ? (ES_CONTINUOUS | ES_SYSTEM_REQUIRED) : ES_CONTINUOUS);
    result->Success();
  } else if (method == "storeSecret") {
    const EncodableValue* value = Arg(args, "secret");
    const std::vector<uint8_t>* bytes = value ? std::get_if<std::vector<uint8_t>>(value) : nullptr;
    result->Success(EncodableValue(bytes != nullptr && StoreSecret(StringArg(args, "alias"), *bytes)));
  } else if (method == "loadSecret") {
    PCREDENTIALW credential = nullptr;
    if (CredReadW(CredentialTarget(StringArg(args, "alias")).c_str(), CRED_TYPE_GENERIC, 0, &credential)) {
      std::vector<uint8_t> bytes(credential->CredentialBlob, credential->CredentialBlob + credential->CredentialBlobSize);
      CredFree(credential);
      result->Success(EncodableValue(bytes));
    } else if (GetLastError() == ERROR_NOT_FOUND) {
      result->Success();
    } else {
      result->Error("credential_store", "Credential Manager is unavailable");
    }
  } else if (method == "deleteSecret") {
    CredDeleteW(CredentialTarget(StringArg(args, "alias")).c_str(), CRED_TYPE_GENERIC, 0);
    result->Success();
  } else if (method == "systemSupported") {
    IBackgroundCopyManager* manager = BitsManager();
    if (manager) manager->Release();
    result->Success(EncodableValue(manager != nullptr));
  } else if (method == "systemEnqueue") {
    result->Success(EncodableValue(BitsEnqueue(args)));
  } else if (method == "systemCancel") {
    BitsCancel(StringArg(args, "id"));
    result->Success();
  } else if (method == "systemQuery") {
    EncodableMap response;
    response[EncodableValue("items")] = EncodableValue(BitsQuery());
    result->Success(EncodableValue(response));
  } else {
    result->NotImplemented();
  }

  if (SUCCEEDED(com)) CoUninitialize();
}

}  // namespace u
