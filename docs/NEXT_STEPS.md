# Next steps: wireless stylus-enabled trackpad

## Product definition

The Android phone is an input device for the Windows computer, not a second whiteboard. The user can open any drawing or teaching application on Windows (Paint, PowerPoint, OneNote, a browser whiteboard, etc.) and use the phone as a comfortable writing surface.

## Interaction contract

- **One finger / stylus:** left mouse button is held while moving the pointer, so the foreground app receives a normal mouse drag/drawing gesture.
- **Tap:** click.
- **Two-finger drag:** send vertical/horizontal wheel input for scrolling or panning.
- **Pinch:** send Ctrl+wheel input for zoom.
- **Gesture arbitration:** a short delay lets a second finger claim navigation before a finger press begins, preventing most accidental dots. Navigation must always release the remote left button.
- **Disconnect safety:** host-side connection close sends a mouse-button release so a dropped phone cannot leave a drag active.

## Implemented in this slice

- Versioned session messages now include pointer move/down/up, scroll, and zoom events.
- Android uses a dedicated input surface instead of the whiteboard screen.
- Windows uses a companion connection screen and hosts a single authenticated input client on private IPv4 interfaces.
- Windows runner exposes a native MethodChannel that maps input events to Win32 SendInput.
- Two-finger gesture recognition emits wheel/pinch input; the Windows bridge turns pinch into Ctrl+wheel.
- The Windows host releases the left mouse button when a client disconnects.
- Unit coverage was expanded for the input event protocol and the stale counter-widget test was replaced with an app smoke test.

## Immediate validation

1. Run flutter pub get, flutter analyze, and flutter test.
2. Run flutter build windows on Windows to compile the native MethodChannel and Win32 input code.
3. Run the companion on Windows and connect an Android phone on the same private Wi-Fi.
4. Open Paint, make it the foreground application, and test drawing, taps, two-finger scrolling, and pinch zoom.
5. Repeat in PowerPoint, OneNote, and a browser-based whiteboard; note application-specific differences.
6. Disconnect while a stroke is active and verify the mouse button is released.
7. Test touch-only and stylus input separately on a real Android device.

## Next implementation phases

### Reliability and usability
- Tune touchpad pointer acceleration/sensitivity and scroll speed.
- Add a dedicated way to move the pointer without drawing, while retaining the simple one-finger drawing workflow.
- Improve gesture arbitration to eliminate any accidental click when a second finger arrives.
- Add rate limiting, input payload validation, connection timeout, session expiry, and reconnection.
- Add QR pairing and a copy/paste-friendly short connection code.
- Show connection loss and host status clearly; make host shutdown release all active input states.

### Windows input fidelity
- Evaluate Windows Pointer Injection for genuine touch contacts and multi-touch injection. Current SendInput emits mouse/wheel events; it cannot reproduce stylus pressure or tilt.
- Test app-specific behavior. Two-finger scroll and Ctrl+wheel zoom are common conventions, not guaranteed by every target app.
- Consider a background/tray companion so the host can remain available without occupying the desktop.

### Release quality
- Test on multiple Android screen sizes and stylus devices.
- Profile end-to-end input latency and dropped events over Wi-Fi.
- Document Windows Firewall setup for Private networks only.
- Package a Windows release and an Android APK for local installation.

## Security constraints

- Keep the initial host restricted to private IPv4 interfaces and trusted local networks.
- Require the random session token and allow only one connected input client.
- Never expose the plain ws:// host to public networks.
- Harden event schemas and rate limits before wider distribution.
