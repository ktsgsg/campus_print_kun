import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/sharing/shared_pdf_service.dart';
import 'l10n/app_localizations.dart';
import 'ui/app_colors.dart';
import 'ui/print_test_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPdfService.init();
  runApp(const CampusPrintKunApp());
}

class CampusPrintKunApp extends StatelessWidget {
  const CampusPrintKunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: const CupertinoThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PrintTestPage(),
    );
  }
}
