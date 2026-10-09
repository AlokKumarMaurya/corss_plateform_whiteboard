# Cross-Platform Whiteboard

A Flutter teaching whiteboard for Windows and web, controlled by an Android phone used as a wireless stylus-enabled input pad. The desktop/browser owns the large canvas; the phone sends real-time pointer, drawing, and gesture input. The phone is not intended to display a second whiteboard and mirror its completed strokes.

## Intended user experience

- Open the large whiteboard on Windows or in a desktop browser for teaching and screen recording.
- Connect an Android phone on the same private Wi-Fi network.
- Use a finger or stylus on the phone's input surface. Direct-touch coordinates move the pointer within the desktop whiteboard canvas; drawing contact creates ink on the desktop canvas.
- Drag with two fingers to pan and pinch to zoom the desktop canvas.
- Use desktop/web tools for the authoritative board, undo/redo, erase, and clear.

## Current implementation status

The main branch contains the local whiteboard foundation. The feature/windows-web-live-session branch is an early WebSocket/session prototype:

- Windows desktop can start a LAN WebSocket host on port 8765.
- The web build can connect to a Windows host using its local IPv4 address and a session code.
- Drawing events use a versioned JSON protocol with normalized coordinates.
- The prototype currently synchronizes board/stroke events between clients. It is transport groundwork, not yet the final mobile input-pad experience.
- Android input-pad UI, remote pointer injection into the desktop canvas, two-finger pan, pinch-to-zoom, and QR pairing still need to be implemented and tested.

## Architecture

- Feature-first folders with domain/data/presentation boundaries.
- GetX for state management, route bindings, and navigation via GetPage.
- Desktop/web is authoritative for canvas state, rendering, transforms, and board mutations.
- Android sends versioned input events (pointer move/down/up, optional stylus metadata, tool commands, pan, and pinch); it does not own a replicated full-size board.
- Normalize phone input coordinates and map them to the desktop canvas viewport. Keep pointer movement separate from drawing contact so moving the pointer does not automatically draw.
- Keep gesture recognition and arbitration on the input side, and apply pan/zoom transforms on the host canvas.
- Keep WebSocket transport behind an abstraction and platform-specific host creation behind conditional imports. Browsers cannot listen on a local network port; the initial LAN host is Windows.
- GetX owns UI state, route bindings, and navigation. Keep protocol/transport and drawing-domain logic separate from widgets.
- User-facing strings are centralized in lib/core/strings/app_strings.dart; reusable UI belongs in lib/shared/widgets/.

## Development

Run these commands from the repository root:

    flutter pub get
    flutter analyze
    flutter test
    flutter build web
    flutter run -d windows
    flutter run -d chrome

## Current prototype smoke test

1. Run flutter run -d windows and click **Start Windows host**.
2. Keep the Windows app open. Copy a displayed private IPv4 address and the session code.
3. Run flutter run -d chrome on the same PC, or open the web build from a local HTTP origin.
4. In the web app, enter the Windows IPv4 address and session code, then connect.
5. The current prototype synchronizes drawing/board events between the clients. This is only a transport smoke test; it does not yet validate the intended phone-as-input-pad workflow.

## Target end-to-end test

1. Start the Windows host and connect an Android phone on the same private Wi-Fi.
2. Move the stylus without drawing and verify the desktop canvas pointer follows without adding ink.
3. Press and write on the phone; verify strokes render on the desktop canvas in real time.
4. Drag two fingers to pan and pinch to zoom; verify gestures do not create strokes.
5. Verify undo/redo/erase/clear, disconnect during a stroke, reconnect, and host shutdown behavior.
6. Separately build and test the web canvas. The browser cannot listen for incoming local WebSocket connections.

A deployed HTTPS web app cannot generally connect to a plain ws:// LAN endpoint because of mixed-content restrictions. A production web deployment needs a secure local companion/relay design.

## Package note

The requested clean_util package name did not resolve on pub.dev, so it is intentionally not included. Confirm the exact package URL if a different package was intended.
