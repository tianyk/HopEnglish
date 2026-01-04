import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopenglish/constants/app_strings.dart';
import 'package:hopenglish/pages/home_page.dart';
import 'package:hopenglish/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HopEnglishApp());
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
      home: const HomePage(),
    );
  }
}
