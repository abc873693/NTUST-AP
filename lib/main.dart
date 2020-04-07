import 'package:ap_common/utils/preferences.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init(
    key: Constants.key,
    iv: Constants.iv,
  );
  runApp(MyApp());
}
