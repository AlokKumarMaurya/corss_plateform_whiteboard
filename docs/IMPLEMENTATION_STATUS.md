# Implementation Status

## Product goal

This project is a teaching whiteboard for Windows and web, controlled by an Android phone used as a stylus-enabled input pad. The large canvas lives on the desktop/browser so the user can write with a stylus on the phone while recording tutorials. The phone is not intended to display a second, limited-size whiteboard and mirror completed strokes.

The selected interaction model is:
- **Direct-touch pointer mapping:** normalized phone touch/stylus coordinates move the pointer within the desktop whiteboard canvas.
- **Stylus drawing:** pointer-down/move/up while the stylus or drawing contact is active creates strokes on the desktop canvas.
- **Navigation gestures:** two-finger pan and pinch-to-zoom control the desktop canvas; gesture input must not accidentally create ink.
- **Desktop/web owns the board:** canvas state, rendering, undo/redo, erase, and persistence belong to the desktop/web whiteboard. The phone sends input events and receives connection/board status as needed.

## Merged foundation

The local drawing foundation is in main: GetX routes and bindings, reusable canvas/tool widgets, centralized strings, normalized drawing models, undo/redo/clear, and unit tests.

## Current branch: feature/windows-web-live-session

This branch is an initial transport/session prototype, not yet the final mobile-as-input-pad behavior:
- Versioned JSON session protocol with message validation.
- Drawing point/stroke serialization using normalized coordinates and ARGB integer colors.
- Windows-only WebSocket host behind a conditional import.
- WebSocket client built with web_socket_channel, shared by Flutter web and Windows.
- Random session access code, maximum client count, and message size limits.
- Windows host UI shows LAN IPv4 addresses and session code.
- Web UI connects to the Windows host using IP + session code.
- The current prototype synchronizes board/stroke events between clients. It still needs to move to an input-event protocol where the phone controls the host canvas rather than operating as a second whiteboard.

## Validation status

Check the GitHub Actions runs at https://github.com/AlokKumarMaurya/corss_plateform_whiteboard/actions for the latest result on this branch. Do not treat the feature as ready until dependency resolution, flutter analyze, flutter build web, flutter test, and flutter build windows pass on the latest commit, and the real Windows-to-mobile/browser interaction is manually tested.

No actual Windows desktop session or cross-device LAN test has been performed by CI. See docs/NEXT_STEPS.md for the updated validation plan.

## Known limitations / next work

- Refactor the session protocol from board replication to input events: pointer move, pointer down/up, stylus metadata where available, two-finger pan, pinch scale/anchor, and tool commands.
- Add an Android input-pad UI with a full-screen touch surface, connection state, session code/QR join, and explicit drawing/navigation gesture handling.
- Keep Windows/web as the authoritative canvas renderer. Map normalized mobile coordinates to the desktop canvas viewport and keep pointer movement separate from ink creation.
- Implement two-finger pan and pinch-to-zoom on the desktop canvas; define gesture arbitration so two-finger gestures never draw.
- Add a Windows build job and manually test on real hardware with a stylus and phone.
- Add reconnect handling, host-disconnect handling, session expiry, and optional QR pairing.
- Improve event batching/rendering performance for long strokes; profile input-to-render latency on a real network before making performance claims.
- Consider snapshot chunking/compression if future features require board snapshots.
- Add rate limiting, better malformed-event telemetry, and session expiry.
- Add persistent boards and PNG export after the input-pad experience is proven.
- The requested clean_util package name did not resolve on pub.dev, so it remains excluded pending an exact package URL.
