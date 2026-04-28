import 'package:flutter/cupertino.dart';

import 'ui/app_colors.dart';
import 'ui/print_test_page.dart';

void main() {
  runApp(const CampusPrintKunApp());
}

class CampusPrintKunApp extends StatelessWidget {
  const CampusPrintKunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'campus_print_kun',
      theme: const CupertinoThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
      home: const PrintTestPage(),
    );
  }
}
