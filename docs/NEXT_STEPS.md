# Next steps: mobile stylus input pad for desktop/web whiteboard

## Product behavior (source of truth)

The desktop Windows app or web app owns and displays the large whiteboard canvas. An Android phone acts as a wireless stylus-enabled input pad while the user records or teaches from the desktop.

The phone is not a second whiteboard and does not send completed mobile-canvas strokes for replication. It sends real-time input events that control the desktop canvas.

Chosen interactions:
- **Direct touch:** normalized phone coordinates move the pointer within the desktop whiteboard canvas.
- **Ink:** stylus/finger down, move, and up events create strokes on the desktop canvas when drawing mode is active.
- **Navigation:** two-finger drag pans the desktop canvas; pinch-to-zoom scales the desktop canvas around the gesture anchor.
- **Separation:** navigation gestures must never accidentally add ink. Single-contact drawing and two-contact navigation need explicit gesture arbitration.
- **Transport:** begin with Windows host + Android client on the same private Wi-Fi. The web app can be another desktop canvas client where appropriate. A web browser cannot listen on a local port to become the LAN host.

## Current branch slice

feature/windows-web-live-session currently provides the first WebSocket/session prototype: Windows LAN host, web client, a versioned protocol, and synchronized drawing/board events. It is useful transport groundwork, but its current board-replication behavior is not yet the intended phone-as-input-pad interaction. The next implementation slice must change the event model and UI accordingly rather than polishing the current mirrored-canvas behavior.

## Implementation plan

### Phase 1 — Establish the host-canvas input protocol
1. Define versioned input messages for pointer move, pointer down, pointer up, stylus pressure/tilt when supported, tool selection, undo/redo/clear, two-finger pan, and pinch scale plus anchor.
2. Include a stable device/session ID and normalized coordinates; validate event type, coordinate ranges, pointer IDs, message size, and event rates.
3. Keep drawing models and board mutations on the host canvas. Do not treat the phone as an authoritative board or broadcast every completed stroke as the primary interaction.
4. Add protocol unit tests for valid events, malformed payloads, coordinate boundaries, and gesture messages.

### Phase 2 — Desktop canvas input adapter
1. Add a dedicated input adapter/controller that translates remote input messages into canvas actions.
2. Map normalized phone coordinates to the desktop whiteboard viewport, not the whole OS desktop.
3. Ensure pointer movement alone moves the cursor but does not draw; only a valid drawing contact/mode produces ink.
4. Route remote pointer down/move/up through the same drawing pipeline used by local mouse/stylus input so local and remote behavior stays consistent.
5. Apply pan and zoom to the host canvas transform. Preserve the gesture anchor during pinch-to-zoom.
6. Add tests for pointer-to-canvas mapping, drawing state transitions, pan/zoom transforms, disconnect during an active stroke, and avoiding ink during navigation.

### Phase 3 — Android input-pad experience
1. Add an Android-specific full-screen input surface with connection status, host IP/session code, connect/disconnect, and drawing/navigation feedback.
2. Handle stylus and touch events; send pointer movement and drawing contact state in real time.
3. Recognize two-finger pan and pinch-to-zoom, and suppress drawing while those gestures are active.
4. Start with manual IP/session-code entry; add QR pairing after the core interaction is reliable.
5. Keep mobile UI focused on input and essential tools; do not render a duplicate full whiteboard canvas.

### Phase 4 — Connectivity and reliability
1. Verify Windows host + Android input pad on the same private Wi-Fi, including Windows Firewall restricted to Private networks.
2. Verify web build and Windows build; run flutter analyze and flutter test.
3. Test connection loss, host shutdown, reconnect, session expiry, and stale pointer cleanup.
4. Measure end-to-end input latency and dropped/misordered events on real devices. Add batching only if profiling shows it helps without making handwriting feel delayed.
5. Consider secure relay/companion hosting later if users need different networks or a deployed HTTPS web app. A plain ws:// LAN endpoint is not a production solution for arbitrary HTTPS-hosted browsers.

### Phase 5 — Teaching workflow polish
1. Add QR pairing and reconnect UX.
2. Tune stroke smoothing and stylus pressure if the target hardware exposes reliable data.
3. Add board persistence and PNG export after input interaction is stable.
4. Test a complete recording workflow: connect phone, write code/diagrams, pan/zoom, undo/erase, and record the desktop canvas.

## Manual verification checklist

- Start the Windows host and connect an Android phone on the same private Wi-Fi.
- Confirm the phone shows an input surface, not a duplicate board.
- Move the stylus without drawing to move the desktop canvas pointer without adding ink.
- Press and write; confirm ink appears only on the desktop canvas and follows the stylus with acceptable latency.
- Drag two fingers to pan and pinch to zoom; confirm neither gesture creates ink.
- Test undo, redo, clear, disconnect during a stroke, reconnect, and host shutdown.
- Separately confirm the web canvas renders and builds successfully. Browser-hosting on a LAN is not assumed.

## Security / platform constraints

- The random session code is required for WebSocket connection; never log or share it publicly.
- Keep the initial host limited to private LAN use and allow it through Windows Firewall only on Private networks.
- Browsers cannot run a listening local socket. Production hosting over HTTPS needs a secure local companion/relay approach.
- Validate message schemas, coordinate ranges, pointer state, message sizes, and event rates before using the session beyond a trusted local network.
