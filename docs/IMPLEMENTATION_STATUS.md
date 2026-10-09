# Implementation Status

## Product goal

Turn an Android phone into a wireless stylus-enabled trackpad for Windows. The phone provides the comfortable physical writing surface; Windows forwards the input to the currently active application. A separate whiteboard UI is not required.

## Implemented on the current feature branch

- Versioned JSON WebSocket session protocol with pointer and gesture event types.
- Windows host bound to private IPv4 interfaces, protected by a random session token, with a one-client limit.
- Android-specific input-pad screen with one-contact drawing/click behavior and two-contact scroll/pinch gesture handling.
- Windows-specific companion screen for starting/stopping the host and displaying the IP/session code.
- Native Windows MethodChannel backed by Win32 SendInput for relative mouse movement, left button down/up, vertical/horizontal wheel events, and Ctrl+wheel zoom.
- Host-side mouse-button release event when a client disconnects.
- CI runs Dart analysis/tests on Ubuntu and builds the Windows desktop app on Windows.

## Not yet validated

The implementation has not yet been tested on a real Android phone connected to a Windows PC. CI can check Dart code and compile the Windows runner, but cannot validate handwriting feel, pointer speed, application-specific scroll/zoom behavior, or real Wi-Fi latency.

## Known limitations

- The implementation uses relative mouse input. It is intended to behave like a trackpad, not map phone coordinates to a fixed desktop drawing area.
- One-contact drawing is represented as a normal left-button drag. Stylus pressure and tilt are not transmitted.
- Two-finger scrolling is sent as wheel input, and pinch is sent as Ctrl+wheel. The active app decides how to interpret these events.
- The legacy drawing/whiteboard files remain in the repository but are no longer selected by the Android or Windows app routes.
- The plain WebSocket connection is intended only for trusted private LAN use. Do not expose it to public networks.

## Next steps

1. Run latest CI and fix any analysis/test/Windows native build errors.
2. Validate drawing, click, scroll, and pinch behavior in Paint on real hardware.
3. Tune pointer/scroll speed and gesture arbitration based on those results.
4. Add stronger event validation/rate limiting, QR pairing, and reconnect handling.
5. Evaluate Windows Pointer Injection if genuine multi-touch or pressure-sensitive stylus input becomes necessary.
