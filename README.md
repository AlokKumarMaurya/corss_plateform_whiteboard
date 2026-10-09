# Cross-Platform Whiteboard

A Flutter whiteboard for Windows and web, with Android as a wireless writing tablet over the same Wi-Fi network.

## Current status

The initial foundation provides a Flutter package manifest, GetX route setup, shared drawing models, a local canvas, pen color/width controls, eraser, undo/redo, and controller/model tests.

**Not implemented yet:** WebSocket session hosting, phone connection, QR pairing, PNG export, persistent boards, and the web-to-local-companion connection flow.

## Architecture

- Feature-first folders with domain/data/presentation boundaries.
- GetX for state management, bindings, and navigation via `GetPage`.
- Drawing models are separated from canvas rendering and pointer input.
- User-facing strings are centralized in `lib/core/strings/app_strings.dart`.
- Common UI patterns live in `lib/shared/widgets/`.
- Normalized canvas coordinates prepare for different screen sizes and remote input.

## Packages

- `get`: state management, bindings, and navigation.
- `web_socket_channel`: planned for the cross-platform socket client.
- Flutter SDK `CustomPainter` and pointer events: local drawing.

The `clean_util` package has not been added yet because its exact package identity and API need to be confirmed before introducing an unverified dependency.

## Next milestones

1. Verify `flutter pub get`, `flutter analyze`, and `flutter test` locally.
2. Improve stroke rendering performance and implement export.
3. Implement a native Windows WebSocket host and Android connection client.
4. Add short-lived QR pairing credentials and safe reconnection.
5. Support web whiteboard sessions through a local companion connection flow.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
flutter run -d chrome
```

Use a physical Android device to test touch and stylus input. Network behavior must be verified on the same Wi-Fi network. The repository code has not yet been built or exercised in a local Flutter environment.
