#ifndef FLUTTER_PLUGIN_U_PLATFORM_H_
#define FLUTTER_PLUGIN_U_PLATFORM_H_

#include <flutter/encodable_value.h>
#include <flutter/method_result.h>

#include <functional>
#include <memory>
#include <string>
#include <vector>

namespace u {

// Everything a u feature needs to run work off the platform thread and come back to it.
// Flutter method results and event sinks must only be used on the platform thread.
namespace platform {

// Creates the message-only window that receives posted tasks. Call once, on the platform thread.
void Initialize();

// Runs [task] on the platform thread. Safe from any thread; dropped if Initialize never ran.
void Post(std::function<void()> task);

// Runs [work] on a new thread initialised for COM/WinRT (multi-threaded apartment).
void RunInBackground(std::function<void()> work);

// A method result that can be captured by copyable lambdas and answered from Post().
using SharedResult = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>;

std::wstring Widen(const std::string& utf8);
std::string Narrow(const std::wstring& wide);

// The process command line, without the executable (deep links and "Open with" files arrive here).
std::vector<std::wstring> Arguments();

// Remembers the Flutter view; OwnerWindow() returns its top-level window, for dialogs that need an owner.
void SetOwnerWindow(void* hwnd);
void* OwnerWindow();

}  // namespace platform
}  // namespace u

#endif  // FLUTTER_PLUGIN_U_PLATFORM_H_
