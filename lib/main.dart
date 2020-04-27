import 'dart:async';
import 'dart:io';

import 'package:ap_common/utils/preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app.dart';
import 'config/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init(
    key: Constants.key,
    iv: Constants.iv,
  );
  if (Constants.isInDebugMode) {
    runApp(MyApp());
  } else if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    Crashlytics.instance.enableInDevMode = Constants.isInDebugMode;

    // Pass all uncaught errors from the framework to Crashlytics.
    FlutterError.onError = Crashlytics.instance.recordFlutterError;
    runZoned<Future<void>>(() async {
      runApp(MyApp());
    }, onError: Crashlytics.instance.recordError);
  } else {
    // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    runApp(MyApp());
    //TODO add other platform Crashlytics
  }
}
