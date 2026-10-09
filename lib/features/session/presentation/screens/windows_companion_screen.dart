import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:cross_platform_whiteboard/features/session/presentation/widgets/session_panel.dart';
import 'package:flutter/material.dart';

class WindowsCompanionScreen extends StatelessWidget {
  const WindowsCompanionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(Icons.touch_app_rounded, size: 52),
                const SizedBox(height: 12),
                Text(
                  AppStrings.whiteboardTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.whiteboardSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const SessionPanel(),
                const SizedBox(height: 16),
                const Text(
                  'After the phone connects, switch to Paint, PowerPoint, '
                  'OneNote, or another application. Input from the phone is '
                  'sent to the currently active Windows application.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep this companion running while using the input pad. '
                  'Allow it through Windows Firewall on Private networks only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF737D8F), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
