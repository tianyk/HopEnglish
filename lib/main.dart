import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopenglish/src/constants/app_strings.dart';
import 'package:hopenglish/src/pages/home_page.dart';
import 'package:hopenglish/src/services/learning_progress_service.dart';
import 'package:hopenglish/src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HopEnglishApp());
  unawaited(LearningProgressService.instance.ping());
}

/// HopEnglish 应用入口
class HopEnglishApp extends StatelessWidget {
  const HopEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) => AppTextScaleBoundary(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomePage(),
    );
  }
}

class AppTextScaleBoundary extends StatelessWidget {
  final Widget child;

  const AppTextScaleBoundary({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(child: child);
  }
}
