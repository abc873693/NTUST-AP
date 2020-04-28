import 'dart:io';

import 'package:ap_common_firbase/utils/firebase_utils.dart';
import 'package:ntust_ap/pages/home_page.dart';
import 'package:ntust_ap/pages/login_page.dart';
import 'package:ntust_ap/utils/app_localizations.dart';
import 'package:ntust_ap/widgets/share_data_widget.dart';
import 'package:ap_common/models/ap_support_language.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/constants.dart';

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Brightness brightness = Brightness.light;

  ThemeMode themeMode = ThemeMode.system;

  FirebaseAnalytics _analytics;

  @override
  void initState() {
    _analytics = FirebaseUtils.init();
    themeMode = ThemeMode
        .values[Preferences.getInt(Constants.PREF_THEME_MODE_INDEX, 0)];
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return ShareDataWidget(
      this,
      child: ApTheme(
        themeMode,
        child: MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          routes: <String, WidgetBuilder>{
            Navigator.defaultRouteName: (context) => HomePage(),
            LoginPage.routerName: (context) => LoginPage(),
          },
          theme: ApTheme.light,
          darkTheme: ApTheme.dark,
          themeMode: themeMode,
          navigatorObservers: !kIsWeb && (Platform.isAndroid || Platform.isIOS)
              ? [
                  FirebaseAnalyticsObserver(analytics: _analytics),
                ]
              : [],
          localeResolutionCallback:
              (Locale locale, Iterable<Locale> supportedLocales) {
            String languageCode = Preferences.getString(
              Constants.PREF_LANGUAGE_CODE,
              ApSupportLanguageConstants.SYSTEM,
            );
            if (languageCode == ApSupportLanguageConstants.SYSTEM)
              return locale;
            else
              return Locale(
                languageCode,
                languageCode == ApSupportLanguageConstants.ZH ? 'TW' : null,
              );
          },
          localizationsDelegates: [
            const AppLocalizationsDelegate(),
            const ApLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en', 'US'), // English
            const Locale('zh', 'TW'), // Chinese
          ],
        ),
      ),
    );
  }

  void update(ThemeMode mode) {
    setState(() {
      themeMode = mode;
    });
  }
}
