# Next vertical slice: phone-to-laptop drawing

The current CI-verified slice is the local canvas and drawing model. The next slice must prove live Android-to-Windows drawing before adding richer whiteboard features.

## Implementation order

1. Add a versioned, JSON-serializable drawing-event protocol. Use normalized x/y values and integer ARGB colors. Do not transmit Flutter object instances.
2. Add a platform-specific transport abstraction in the domain/application layer and keep socket imports out of drawing models.
3. Implement a native Windows host using `dart:io` WebSocket support, binding only to the active local network interface where feasible and documenting Windows Firewall behavior.
4. Implement the Android client using a WebSocket package and a simple manual IPv4/port entry screen for the first test. Add Android INTERNET permission and clear errors for unreachable hosts.
5. Share the same `DrawingPoint` / `DrawingStroke` command path with local and remote input. The Windows side should render a received point immediately and commit the stroke at end-of-stroke.
6. Add integration tests for protocol JSON serialization, malformed messages, wrong session keys, disconnect handling, and normalized coordinates.
7. Only after the manual-IP proof works, implement one-time/short-lived QR pairing.

## Web constraint

Browser JavaScript cannot start a listening local socket. The web client must connect to a companion host or use a different deployment model. Do not claim the web build can host a local WebSocket server just because the Windows build can.

## Security requirements

- Pairing credentials must be cryptographically random, short-lived, and session-scoped.
- Require explicit authorization before accepting a device.
- Never log pairing secrets.
- Validate message type, session identifier, coordinate range, payload size, and event rate.
- Bind narrowly and explain LAN-only scope; do not ask users to disable their firewall.

## Performance requirements

- Do not rebuild the full board per pointer point. Keep a transient stroke buffer and schedule frame updates.
- Batch network events across a short frame-sized interval rather than sending a large JSON message for every touch event.
- Test a long continuous handwritten stroke on a real Android device and Windows host; profile before claiming latency figures.
