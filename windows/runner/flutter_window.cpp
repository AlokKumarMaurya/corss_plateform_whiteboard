#include "flutter_window.h"

#include <algorithm>
#include <cstdint>
#include <optional>
#include <string>
#include <variant>

#include <windows.h>

#include "flutter/generated_plugin_registrant.h"

namespace {

double ReadNumber(const flutter::EncodableMap* arguments, const char* name) {
  if (arguments == nullptr) return 0.0;
  const auto iterator = arguments->find(flutter::EncodableValue(std::string(name)));
  if (iterator == arguments->end()) return 0.0;
  if (const auto* value = std::get_if<double>(&iterator->second)) return *value;
  if (const auto* value = std::get_if<int32_t>(&iterator->second)) {
    return static_cast<double>(*value);
  }
  if (const auto* value = std::get_if<int64_t>(&iterator->second)) {
    return static_cast<double>(*value);
  }
  return 0.0;
}

void SendMouseInput(DWORD flags, LONG dx = 0, LONG dy = 0,
                    DWORD mouse_data = 0) {
  INPUT input{};
  input.type = INPUT_MOUSE;
  input.mi.dx = dx;
  input.mi.dy = dy;
  input.mi.mouseData = mouse_data;
  input.mi.dwFlags = flags;
  SendInput(1, &input, static_cast<UINT>(sizeof(INPUT)));
}

void SendControlKey(bool key_up) {
  INPUT input{};
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = VK_CONTROL;
  input.ki.dwFlags = key_up ? KEYEVENTF_KEYUP : 0;
  SendInput(1, &input, sizeof(INPUT));
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  input_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "cross_platform_whiteboard/system_input",
          &flutter::StandardMethodCodec::GetInstance());
  input_channel_->SetMethodCallHandler(
      [](const auto& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());

        if (call.method_name() == "moveAbsolute") {
          const double normalized_x =
              std::clamp(ReadNumber(arguments, "x"), 0.0, 1.0);
          const double normalized_y =
              std::clamp(ReadNumber(arguments, "y"), 0.0, 1.0);
          const int left = GetSystemMetrics(SM_XVIRTUALSCREEN);
          const int top = GetSystemMetrics(SM_YVIRTUALSCREEN);
          const int width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
          const int height = GetSystemMetrics(SM_CYVIRTUALSCREEN);
          if (width > 0 && height > 0) {
            const int x = left + static_cast<int>(normalized_x * (width - 1) + 0.5);
            const int y = top + static_cast<int>(normalized_y * (height - 1) + 0.5);
            SetCursorPos(x, y);
          }
        } else if (call.method_name() == "moveRelative") {
          const LONG dx = static_cast<LONG>(
              std::clamp(ReadNumber(arguments, "dx") * 1.8, -2000.0, 2000.0));
          const LONG dy = static_cast<LONG>(
              std::clamp(ReadNumber(arguments, "dy") * 1.8, -2000.0, 2000.0));
          SendMouseInput(MOUSEEVENTF_MOVE, dx, dy);
        } else if (call.method_name() == "buttonDown") {
          SendMouseInput(MOUSEEVENTF_LEFTDOWN);
        } else if (call.method_name() == "buttonUp") {
          SendMouseInput(MOUSEEVENTF_LEFTUP);
        } else if (call.method_name() == "scroll") {
          const LONG dx = static_cast<LONG>(
              std::clamp(ReadNumber(arguments, "dx") * 8.0, -1200.0, 1200.0));
          const LONG dy = static_cast<LONG>(
              std::clamp(ReadNumber(arguments, "dy") * 8.0, -1200.0, 1200.0));
          if (dy != 0) SendMouseInput(MOUSEEVENTF_WHEEL, 0, 0, static_cast<DWORD>(dy));
          if (dx != 0) SendMouseInput(MOUSEEVENTF_HWHEEL, 0, 0, static_cast<DWORD>(dx));
        } else if (call.method_name() == "zoom") {
          const LONG delta = static_cast<LONG>(
              std::clamp(ReadNumber(arguments, "delta"), -1200.0, 1200.0));
          if (delta != 0) {
            SendControlKey(false);
            SendMouseInput(MOUSEEVENTF_WHEEL, 0, 0, delta);
            SendControlKey(true);
          }
        } else {
          result->NotImplemented();
          return;
        }

        result->Success(flutter::EncodableValue());
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });
  flutter_controller_->ForceRedraw();
  return true;
}

void FlutterWindow::OnDestroy() {
  input_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
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
      if (flutter_controller_) {
        flutter_controller_->engine()->ReloadSystemFonts();
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
