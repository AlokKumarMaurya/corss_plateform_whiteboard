# Cross-Platform Whiteboard

A Flutter whiteboard designed for Windows and web, with Android planned as a wireless finger/stylus writing tablet over the same Wi-Fi network.

## Current implementation

The main branch contains the local whiteboard foundation. The feature/windows-web-live-session branch adds the first live-session slice:

- Windows desktop can start a LAN WebSocket host on port 8765.
- The web build can connect to a Windows host using its local IPv4 address and a session code.
- Drawing events use a versioned JSON protocol with normalized coordinates.
- Pen strokes, remote stroke updates, undo, redo, clear, and initial board snapshots are synchronized.
- The server requires a cryptographically random session code and limits clients and message sizes.
- GetX owns UI state, route bindings, and session state; the transport and protocol live in separate feature layers.

This is an early manual-testing milestone, not a finished multi-device release. Android pairing/client UI, QR pairing, persistent boards, and PNG export are not implemented yet.

## Architecture

- Feature-first folders with domain/data/presentation boundaries.
- GetX for state management, bindings, and navigation via GetPage.
- Drawing models use numeric ARGB values and normalized coordinates for transport portability.
- User-facing strings are centralized in lib/core/strings/app_strings.dart.
- Common UI patterns live in lib/shared/widgets/.
- Windows-only host code is loaded through a conditional import, so the web build does not import dart:io.

## Development

Run these commands from the repository root:

    flutter pub get
    flutter analyze
    flutter test
    flutter build web
    flutter run -d windows
    flutter run -d chrome

## Test Windows + web on the same network

1. Run flutter run -d windows and click Start Windows host.
2. Keep the Windows app open. Copy one displayed local IPv4 address and the session code.
3. Run flutter run -d chrome on the same PC, or open the web build from a local HTTP origin.
4. In the web app, enter the Windows IPv4 address and session code, then connect.
5. Draw on either canvas. Test a few strokes, undo, redo, and clear.
6. If connection fails, verify both devices are on the same private Wi-Fi/LAN and allow the app through Windows Firewall for Private networks. Do not disable the firewall.

The browser cannot listen for incoming local WebSocket connections. In this design Windows is the host and web is a client. A deployed HTTPS web site cannot connect to this plain ws:// LAN endpoint in all browsers because of mixed-content restrictions; use the local development web origin for this milestone. A production web deployment needs a secure local companion/relay design.

## Package note

The requested clean_util package name did not resolve on pub.dev during CI, so it is intentionally not included. Confirm the exact package URL if a different package was intended.
