import 'dart:io';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firbase/utils/firebase_analytics_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:ntust_ap/api/course_helper.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/scaffold/course_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:ntust_ap/config/constants.dart';
import 'package:ntust_ap/utils/captcha_utils.dart';

class CoursePage extends StatefulWidget {
  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  CourseData courseData;

  CourseState _state = CourseState.loading;

  @override
  void initState() {
    _loadCache();
    if (CourseHelper.isLogin)
      _getCourse();
    else
      _login();
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("CoursePage", "course_page.dart");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CourseScaffold(
      state: _state,
      courseData: courseData,
      onRefresh: () async {
        _getCourse();
      },
      isShowSearchButton: false,
    );
  }

  void _loadCache() async {
    courseData = CourseData.load('latest');
    if (courseData != null && courseData.courseTables.timeCode != null)
      setState(() => _state = CourseState.finish);
  }

  String validationCode = '';

  void _login() async {
    var username = Preferences.getString(Constants.PREF_USERNAME, '');
    var password = Preferences.getStringSecurity(Constants.PREF_PASSWORD, '');
    var bodyBytes = await CourseHelper.instance.getValidationImage();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      validationCode = await CaptchaUtils.extractByTfLite(
        bodyBytes: bodyBytes,
        type: SystemType.course,
      );
    }
    CourseHelper.instance.login(
      username: username,
      password: password,
      validationCode: validationCode,
      callback: GeneralCallback(
        onError: (GeneralResponse e) async {
          if (e.statusCode == 4001) {
            print('4001');
            _login();
          }
        },
        onFailure: (DioError e) {
          ApUtils.showToast(context, ApLocalizations.dioError(context, e));
        },
        onSuccess: (GeneralResponse data) async {
          await CourseHelper.instance.checkLogin();
          _getCourse();
        },
      ),
    );
  }

  void _getCourse() async {
    courseData = await CourseHelper.instance.getCourseTable();
    courseData.save('latest');
    if (mounted) {
      setState(() {
        if (courseData != null && courseData.courseTables.timeCode != null)
          _state = CourseState.finish;
        else
          _state = CourseState.error;
      });
    }
  }
}
