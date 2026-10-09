# Cross-Platform Whiteboard

A Flutter whiteboard for Windows and web, with Android as a wireless writing tablet over the same Wi-Fi network.

## Status

This repository is being initialized. The first milestone is the shared local drawing canvas. Phone-to-laptop streaming, QR pairing, and production hardening are not implemented yet.

## Architecture goals

- Clean architecture with a feature-first structure.
- GetX for state management and route management through `GetMaterialApp` / `GetPage`.
- Shared drawing domain models that do not depend on Flutter widgets.
- Reusable UI widgets and centralized app strings/messages.
- Shared canvas rendering and pointer input for local drawing.
- A platform-specific connection layer: native Windows host and Android client; browser-host behavior will be addressed explicitly rather than importing `dart:io` into web code.

## Planned milestones

1. Drawing canvas and pure Dart stroke models.
2. Local drawing tools: pen color/size, eraser, undo/redo, clear.
3. Windows-hosted WebSocket session and Android drawing client.
4. QR pairing, expiring credentials, reconnect behavior, and same-network documentation.
5. Web client and supported companion-host connection flow.

## Development

Use a current stable Flutter SDK. After the Flutter scaffold and dependencies are committed:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Web can be run with `flutter run -d chrome`; Android should be tested on a physical device for touch and stylus behavior.

## Quality principles

- Keep domain models independent of widgets and networking.
- Centralize user-facing strings and route names.
- Reuse common widgets rather than duplicate UI patterns.
- Never mark a feature complete until it has been tested on its target platform.
