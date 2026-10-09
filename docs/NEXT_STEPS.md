# Next steps: wireless stylus-enabled trackpad

## Product definition

The Android phone is an input device for the Windows computer, not a second whiteboard. The user can open any drawing or teaching application on Windows (Paint, PowerPoint, OneNote, a browser whiteboard, etc.) and use the phone as a comfortable writing surface.

## Implemented

- Versioned JSON session protocol and private-LAN WebSocket connection.
- Windows companion with native Win32 mouse, button, wheel, and Ctrl+wheel input.
- Android input pad with one-finger writing, tap-to-click, and two-finger scroll/pinch gestures.
- Host-side release of the mouse button when the client disconnects.
- **Input controls:** compact Write/Move toolbar, adjustable pointer and scroll sensitivity (scroll up to 14×), and app-bar disconnect action while connected.
- **Pointer mapping:** Trackpad mode retains relative cursor movement; Tablet mode maps touch positions to the Windows desktop with edge snapping, adjustable precision zoom, and a movable mapped desktop area.
- **Stylus writing:** hover-capable styluses can reposition the pointer between separate strokes without drawing.
- GetX bindings and tests/CI for Dart analysis, tests, and Windows compilation.

## Current validation

The base connection and drawing flow has been reported as working on real devices. This controls milestone must pass CI and then be checked on the same phone/PC setup to verify that Move mode never draws, Write mode continues to draw, and sensitivity controls have a predictable effect.

## Next implementation phases

### Reliability and pairing
- Add QR pairing after choosing a camera/QR dependency and validating Android camera permissions.
- Add reconnection UX, connection timeout, session expiry, and a visible disconnect state.
- Add input payload validation and event-rate limiting.
- Persist user preferences for pointer and scroll sensitivity between app launches.
- Validate Tablet mode edge snapping and adjustable mapping zoom/area with multi-stroke letters (T, R, P) on a real phone/Windows setup, including multi-monitor desktops.
- Verify stylus hover repositioning on supported Android stylus hardware.

### Windows input fidelity
- Evaluate Windows Pointer Injection for genuine touch contacts and pressure/tilt-aware stylus input. Current SendInput emits mouse/wheel events.
- Test scroll and Ctrl+wheel zoom across target apps; application behavior is not uniform.
- Consider a background/tray companion so the host can remain available without occupying the desktop.

### Release quality
- Test on multiple Android screen sizes and stylus devices.
- Profile end-to-end input latency and dropped events over Wi-Fi.
- Package a Windows release and an Android APK for local installation.

## Security constraints

- Keep the host restricted to private IPv4 interfaces and trusted local networks.
- Require the session code and permit only one connected input client.
- Never expose the unencrypted ws:// endpoint to public networks.
- Harden event schemas and rate limits before wider distribution.
