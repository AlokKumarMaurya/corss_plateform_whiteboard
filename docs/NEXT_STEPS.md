# Next steps: live whiteboard across devices

## Current branch slice

feature/windows-web-live-session adds the protocol, Windows LAN host, and web client. The Windows app starts the session; browser JavaScript cannot listen on a local socket, so the browser connects as a client.

## Manual verification

1. Build/run the Windows desktop app and start a session.
2. Build/run the web app from a local HTTP origin on the same PC or network.
3. Connect with a Windows LAN IPv4 address and session code.
4. Verify local drawing in each direction, then undo, redo, clear, and snapshot on connect.
5. Repeat with another browser tab and inspect behavior if one client disconnects.
6. Validate Windows Firewall prompts on a private network without disabling the firewall.

## Follow-up implementation order

1. Add an automated Windows desktop build to CI and keep web compilation in CI.
2. Fix any issues discovered by the manual Windows↔web session test.
3. Implement the Android client with the same versioned message protocol and manual IP/code entry.
4. Add short-lived QR pairing and explicit join authorization.
5. Add reconnect state, host-disconnect handling, and session expiry.
6. Optimize long strokes with event batching and transient point buffers; profile real device latency before making performance claims.
7. Add board persistence and PNG export.

## Security / platform constraints

- The session code is random and required for WebSocket upgrade; never log or share it publicly.
- The Windows host binds on IPv4 LAN interfaces and accepts a limited number of clients.
- Keep the host limited to private LAN use and allow it through Windows Firewall only on Private networks.
- Browsers cannot run a listening local socket. Production hosting over HTTPS needs a secure local companion/relay approach; this initial local-development slice uses ws://.
- Validate event schemas, coordinates, message sizes, and event rates before using the session beyond a trusted local network.
