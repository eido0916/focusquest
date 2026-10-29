#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Launch the local AI gateway as an app companion. The gateway reads its own
// API credential from the environment; no key is compiled into the app.
class LocalTaskAiProcess {
 public:
  LocalTaskAiProcess() {
    wchar_t executable[32768];
    const DWORD length = ::GetModuleFileNameW(nullptr, executable, 32768);
    if (length == 0 || length >= 32768) return;
    std::wstring directory(executable, length);
    const auto separator = directory.find_last_of(L"\\/");
    if (separator == std::wstring::npos) return;
    directory.resize(separator);
    const std::wstring server = directory + L"\\focusquest_task_ai.exe";
    if (::GetFileAttributesW(server.c_str()) == INVALID_FILE_ATTRIBUTES) return;
    STARTUPINFOW startup = {};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process = {};
    if (::CreateProcessW(server.c_str(), nullptr, nullptr, nullptr, FALSE,
                         CREATE_NO_WINDOW, nullptr, directory.c_str(),
                         &startup, &process)) {
      handle_ = process.hProcess;
      ::CloseHandle(process.hThread);
    }
  }
  ~LocalTaskAiProcess() {
    if (handle_ != nullptr) {
      if (::WaitForSingleObject(handle_, 0) == WAIT_TIMEOUT) {
        ::TerminateProcess(handle_, 0);
      }
      ::CloseHandle(handle_);
    }
  }
 private:
  HANDLE handle_ = nullptr;
};

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  LocalTaskAiProcess task_ai;
  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"focusquest", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
