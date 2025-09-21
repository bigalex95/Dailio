#include "flutter_window.h"

#include <optional>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <psapi.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetupMethodChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::SetupMethodChannel() {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "dailio/foreground_app",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        HandleMethodCall(call, std::move(result));
      });

  method_channel_ = std::move(channel);
}

void FlutterWindow::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const std::string& method = method_call.method_name();
  
  if (method == "getForegroundApp") {
    GetForegroundAppName(std::move(result));
  } else if (method == "checkPermissions") {
    // Windows doesn't require special permissions for getting foreground window
    result->Success(flutter::EncodableValue(true));
  } else if (method == "requestPermissions") {
    // No permissions needed on Windows
    result->Success(flutter::EncodableValue(false));
  } else if (method == "getPlatformInfo") {
    GetPlatformInfo(std::move(result));
  } else if (method == "test") {
    result->Success(flutter::EncodableValue("success"));
  } else {
    result->NotImplemented();
  }
}

void FlutterWindow::GetForegroundAppName(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  HWND foregroundWindow = GetForegroundWindow();
  if (!foregroundWindow) {
    result->Error("NO_WINDOW", "Could not get foreground window", nullptr);
    return;
  }

  // Get the process ID of the foreground window
  DWORD processId;
  GetWindowThreadProcessId(foregroundWindow, &processId);

  // Open the process to get its executable name
  HANDLE process = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, processId);
  if (!process) {
    result->Error("NO_PROCESS", "Could not open process", nullptr);
    return;
  }

  // Get the executable name
  wchar_t processName[MAX_PATH];
  DWORD processNameLength = MAX_PATH;
  
  if (QueryFullProcessImageNameW(process, 0, processName, &processNameLength)) {
    CloseHandle(process);
    
    // Extract just the filename from the full path
    std::wstring fullPath(processName);
    size_t lastSlash = fullPath.find_last_of(L"\\");
    std::wstring fileName = (lastSlash != std::wstring::npos) ? 
                           fullPath.substr(lastSlash + 1) : fullPath;
    
    // Remove .exe extension if present
    size_t dotPos = fileName.find_last_of(L".");
    if (dotPos != std::wstring::npos && fileName.substr(dotPos) == L".exe") {
      fileName = fileName.substr(0, dotPos);
    }
    
    // Convert to UTF-8 string
    int utf8Length = WideCharToMultiByte(CP_UTF8, 0, fileName.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string utf8String(utf8Length - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, fileName.c_str(), -1, &utf8String[0], utf8Length, nullptr, nullptr);
    
    result->Success(flutter::EncodableValue(utf8String));
  } else {
    CloseHandle(process);
    result->Error("GET_NAME_FAILED", "Could not get process name", nullptr);
  }
}

void FlutterWindow::GetPlatformInfo(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  flutter::EncodableMap info;
  info[flutter::EncodableValue("platform")] = flutter::EncodableValue("Windows");
  info[flutter::EncodableValue("supported")] = flutter::EncodableValue(true);
  info[flutter::EncodableValue("hasPermissions")] = flutter::EncodableValue(true);
  info[flutter::EncodableValue("requiresPermissions")] = flutter::EncodableValue(false);
  info[flutter::EncodableValue("permissionsLocation")] = flutter::EncodableValue("None required");
  
  // Get Windows version
  OSVERSIONINFOW osvi;
  ZeroMemory(&osvi, sizeof(OSVERSIONINFOW));
  osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOW);
  
  // Note: GetVersionEx is deprecated but still works for this purpose
  #pragma warning(suppress: 4996)
  if (GetVersionExW(&osvi)) {
    std::string version = std::to_string(osvi.dwMajorVersion) + "." + 
                         std::to_string(osvi.dwMinorVersion) + "." + 
                         std::to_string(osvi.dwBuildNumber);
    info[flutter::EncodableValue("version")] = flutter::EncodableValue(version);
  }
  
  result->Success(flutter::EncodableValue(info));
}
