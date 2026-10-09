# Wireless Stylus Pad

A Flutter Android app that turns a phone into a wireless stylus-enabled trackpad for a Windows PC. The phone sends real-time input events to a small Windows companion, which injects mouse and scroll input into the currently active desktop application.

**This project does not need its own web whiteboard.** Use Paint, PowerPoint, OneNote, a browser-based whiteboard, or another application already installed on Windows.

## Target interaction

- One finger or stylus contact holds the left mouse button while movement controls the pointer, allowing handwriting in the active application.
- A short one-finger tap sends a click.
- Two-finger movement sends scroll/pan input.
- Pinching apart and together sends Ctrl+mouse-wheel zoom input.
- Switching to a different Windows application changes the target automatically because input is sent to the foreground application.
- If the phone disconnects while drawing, the Windows host sends a mouse-button release to avoid a stuck drag.

## Architecture

- **Android / Flutter:** full-screen touch surface, stylus/touch event collection, gesture arbitration, and connection UI.
- **Windows / Flutter:** private-LAN WebSocket host, session code, and connection UI.
- **Windows native runner:** a MethodChannel backed by Win32 SendInput injects relative pointer movement, left-button down/up, wheel scrolling, horizontal scrolling, and Ctrl+wheel zoom.
- **Transport:** versioned JSON messages over WebSocket on the same private Wi-Fi/LAN. Windows listens on port 8765 and permits one connected input client.
- **State management:** GetX controllers and bindings; protocol, transport, presentation, and native input remain separate.

## Development

Install Flutter and enable the Windows desktop target. Then run:

    flutter pub get
    flutter analyze
    flutter test
    flutter run -d windows

On the Android phone, enable USB debugging and run:

    flutter run -d <android-device-id>

Build the Windows companion with:

    flutter build windows

## First real-device test

1. Connect Windows and Android to the same trusted private Wi-Fi network.
2. Run the Windows companion and click **Start Windows companion**.
3. Copy one of the private IPv4 addresses and the 10-character session code displayed by Windows.
4. In the Android app, enter the address and code, then connect.
5. Open Paint on Windows and make sure Paint is the active application.
6. Use the phone's touch surface to write; verify Paint receives the strokes.
7. Move two fingers together to scroll/pan. Pinch apart or together to test Ctrl+wheel zoom.
8. Disconnect during a stroke and verify Windows releases the left mouse button.

Allow the Windows companion through Windows Firewall on **Private networks only**. Do not disable the firewall or expose the host to public networks.

## Known limitations

- The first implementation uses relative mouse input. It is a trackpad, not a mapped graphics tablet, so lift-and-reposition behavior and cursor speed will need tuning for handwriting.
- Standard mouse input does not carry genuine stylus pressure or tilt. Pressure-sensitive drawing will require a separate Windows Pointer/pen-injection approach and compatible app support.
- Scroll and zoom are interpreted by the active application. Ctrl+wheel zoom is common but not universal; applications can override these gestures.
- The WebSocket endpoint is for trusted local-network use and uses an unencrypted ws:// connection. Do not use it on public Wi-Fi. Secure pairing, event-rate limiting, and broader threat hardening remain follow-up work.
- QR pairing, automatic reconnect, configurable pointer speed, and an installable Windows background/tray experience are planned after real-device input testing.

The original whiteboard/drawing files are legacy prototype code and are not part of the intended input-pad workflow.
