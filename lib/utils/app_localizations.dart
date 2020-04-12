import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(Locale locale) {
    AppLocalizations.locale = locale;
  }

  static Locale locale;

  String get changeEmail => _vocabularies['changeEmail'];

  String get hasPreScoreHint => _vocabularies['hasPreScoreHint'];

  String get aboutOpenSourceContent =>
      _vocabularies['about_open_source_content'];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'NTUST AP',
      'about_open_source_content':
          'https://github.com/abc873693/NTUST-AP\n\nThis project is licensed under the terms of the MIT license:\nThe MIT License (MIT)\n\nCopyright &#169; 2020 Rainvisitor\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
    },
    'zh': {
      'app_name': '台科校務通',
      'about_open_source_content':
          'https://github.com/abc873693/NTUST-AP\n\n本專案採MIT 開放原始碼授權：\nThe MIT License (MIT)\n\nCopyright &#169; 2020 Rainvisitor\n\nThis project is Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
    },
  };

  Map get _vocabularies {
    return _localizedValues[locale.languageCode] ?? _localizedValues['en'];
  }

  String get appName => _vocabularies['app_name'];
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

class CupertinoEnDefaultLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const CupertinoEnDefaultLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(Locale('zh'));

  @override
  bool shouldReload(CupertinoEnDefaultLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultCupertinoLocalizations.delegate(en_US)';
}
