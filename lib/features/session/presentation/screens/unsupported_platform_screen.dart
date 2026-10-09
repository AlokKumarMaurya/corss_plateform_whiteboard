import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:flutter/material.dart';

class UnsupportedPlatformScreen extends StatelessWidget {
  const UnsupportedPlatformScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.devices_other_rounded, size: 48),
              SizedBox(height: 16),
              Text(
                'Use the Android app as the input pad and the Windows app as the companion.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Open Paint, PowerPoint, OneNote, or a browser whiteboard separately. '
                'This project does not need its own web whiteboard.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
