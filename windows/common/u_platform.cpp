#include "u_platform.h"

#include <windows.h>
#include <objbase.h>
#include <shellapi.h>

#include <thread>

namespace u {
namespace platform {

namespace {

constexpr UINT kTaskMessage = WM_APP + 0x60;
constexpr wchar_t kWindowClass[] = L"UPlatformTaskWindow";
HWND g_window = nullptr;
HWND g_owner = nullptr;

LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == kTaskMessage) {
    std::unique_ptr<std::function<void()>> task(reinterpret_cast<std::function<void()>*>(lparam));
    if (task && *task) (*task)();
    return 0;
  }
  return DefWindowProcW(window, message, wparam, lparam);
}

}  // namespace

void Initialize() {
  if (g_window != nullptr) return;
  HINSTANCE instance = GetModuleHandleW(nullptr);
  WNDCLASSEXW descriptor = {};
  descriptor.cbSize = sizeof(descriptor);
  descriptor.lpfnWndProc = WindowProc;
  descriptor.hInstance = instance;
  descriptor.lpszClassName = kWindowClass;
  RegisterClassExW(&descriptor);
  g_window = CreateWindowExW(0, kWindowClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE, nullptr, instance, nullptr);
}

void Post(std::function<void()> task) {
  if (g_window == nullptr) return;
  auto* heap = new std::function<void()>(std::move(task));
  if (!PostMessageW(g_window, kTaskMessage, 0, reinterpret_cast<LPARAM>(heap))) delete heap;
}

void RunInBackground(std::function<void()> work) {
  std::thread([work = std::move(work)]() {
    const HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    try {
      work();
    } catch (...) {
      // Never let a background failure take the process down.
    }
    if (SUCCEEDED(hr)) CoUninitialize();
  }).detach();
}

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

std::vector<std::wstring> Arguments() {
  std::vector<std::wstring> out;
  int count = 0;
  LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &count);
  if (argv == nullptr) return out;
  for (int i = 1; i < count; i++) out.emplace_back(argv[i]);
  LocalFree(argv);
  return out;
}

void SetOwnerWindow(void* hwnd) { g_owner = static_cast<HWND>(hwnd); }

// The view is parented to the app window only after plugins register, so resolve it on use.
void* OwnerWindow() { return g_owner == nullptr ? nullptr : GetAncestor(g_owner, GA_ROOT); }

}  // namespace platform
}  // namespace u
