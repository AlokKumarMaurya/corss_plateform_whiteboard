import 'package:cross_platform_whiteboard/app/routes/app_pages.dart';
import 'package:cross_platform_whiteboard/app/theme/app_theme.dart';
import 'package:cross_platform_whiteboard/core/strings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WhiteboardApp extends StatelessWidget {
  const WhiteboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
