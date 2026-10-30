#include "flutter_window.h"

#include <optional>
#include <algorithm>
#include <flutter/standard_method_codec.h>

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
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  display_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "dev.focusquest/display",
      &flutter::StandardMethodCodec::GetInstance());
  display_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() != "setOrientation") {
          result->NotImplemented();
          return;
        }
        const auto* mode = std::get_if<std::string>(call.arguments());
        if (!mode || (*mode != "portrait" && *mode != "landscape")) {
          result->Error("invalid_orientation", "Expected portrait or landscape");
          return;
        }
        ApplyDisplayOrientation(*mode == "landscape");
        result->Success();
      });
  ApplyDisplayOrientation(false);

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
  display_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::ApplyDisplayOrientation(bool landscape) {
  const HWND window = GetHandle();
  MONITORINFO monitor{sizeof(MONITORINFO)};
  if (!GetMonitorInfo(MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST), &monitor)) return;
  if (IsZoomed(window)) ShowWindow(window, SW_RESTORE);
  RECT outer{}, client{};
  GetWindowRect(window, &outer);
  GetClientRect(window, &client);
  const int frame_width = (outer.right - outer.left) - client.right;
  const int frame_height = (outer.bottom - outer.top) - client.bottom;
  const double dpi = GetDpiForWindow(window) / 96.0;
  const int available_width = monitor.rcWork.right - monitor.rcWork.left;
  const int available_height = monitor.rcWork.bottom - monitor.rcWork.top;
  const int max_width = (std::max)(1, available_width - frame_width - 24);
  const int max_height = (std::max)(1, available_height - frame_height - 24);
  int width, height;
  if (landscape) {
    width = (std::min)(max_width, static_cast<int>(1280 * dpi));
    height = static_cast<int>(width * 9.0 / 16);
    if (height > max_height) {
      height = max_height;
      width = static_cast<int>(height * 16.0 / 9);
    }
  } else {
    height = (std::min)(max_height, static_cast<int>(900 * dpi));
    width = static_cast<int>(height * 390.0 / 844);
    if (width > max_width) {
      width = max_width;
      height = static_cast<int>(width * 844.0 / 390);
    }
  }
  width += frame_width;
  height += frame_height;
  SetWindowPos(window, nullptr,
      monitor.rcWork.left + (available_width - width) / 2,
      monitor.rcWork.top + (available_height - height) / 2,
      width, height, SWP_NOZORDER | SWP_NOACTIVATE);
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
