import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'src/locale_manager.dart';
import 'src/riverpod_devtools_extension.dart';

void main() {
  runApp(const RiverpodDevToolsExtensionApp());
}

class RiverpodDevToolsExtensionApp extends StatefulWidget {
  const RiverpodDevToolsExtensionApp({super.key});

  @override
  State<RiverpodDevToolsExtensionApp> createState() =>
      _RiverpodDevToolsExtensionAppState();
}

class _RiverpodDevToolsExtensionAppState
    extends State<RiverpodDevToolsExtensionApp> {
  final LocaleManager _localeManager = LocaleManager();

  @override
  void dispose() {
    _localeManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeManager,
      builder: (context, child) {
        return DevToolsExtension(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: _localeManager.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('zh'), // Chinese
            ],
            home: RiverpodDevToolsExtension(localeManager: _localeManager),
          ),
        );
      },
    );
  }
}
