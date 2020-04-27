import 'dart:io';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/course_notify_data.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common_firbase/utils/firebase_analytics_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:ntust_ap/api/course_helper.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/scaffold/course_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:ntust_ap/api/stu_helper.dart';
import 'package:ntust_ap/utils/captcha_utils.dart';

class CoursePage extends StatefulWidget {
  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  CourseData courseData;
  CourseNotifyData notifyData;

  CourseState _state = CourseState.loading;

  String get courseCacheKey => '${StuHelper.instance.username}'
      '_latest'
      '_${ApLocalizations.locale.languageCode}';

  String get courseNotifyCacheKey => '${StuHelper.instance.username}'
      '_latest';

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
      notifyData: notifyData,
      courseNotifySaveKey: courseNotifyCacheKey,
      onNotifyClick: (courseNotify, _state) {
        switch (_state) {
          case CourseNotifyState.schedule:
            FirebaseAnalyticsUtils.instance.logAction(
              'notify_course_create',
              'create',
            );
            break;
          case CourseNotifyState.cancel:
            FirebaseAnalyticsUtils.instance.logAction(
              'notify_course_cancel',
              'cancel',
            );
            break;
        }
      },
    );
  }

  void _loadCache() async {
    courseData = CourseData.load(courseCacheKey);
    notifyData = CourseNotifyData.load(courseNotifyCacheKey);
    if (courseData != null && courseData.courseTables.timeCode != null)
      setState(() => _state = CourseState.finish);
  }

  String validationCode = '';

  void _login() async {
    var bodyBytes = await CourseHelper.instance.getValidationImage();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      validationCode = await CaptchaUtils.extractByTfLite(
        bodyBytes: bodyBytes,
        type: SystemType.course,
      );
    }
    CourseHelper.instance.login(
      username: StuHelper.instance.username,
      password: StuHelper.instance.password,
      validationCode: validationCode,
      callback: GeneralCallback(
        onError: (GeneralResponse e) async {
          if (e.statusCode == 4001) {
            print('4001');
            if (CourseHelper.instance.captchaErrorCount < 10)
              _login();
            else {
              FirebaseAnalyticsUtils.instance.logCaptchaErrorEvent(
                'course',
                CourseHelper.instance.captchaErrorCount,
              );
              CourseHelper.instance.captchaErrorCount = 0;
            }
          } else {
            //TODO
          }
        },
        onFailure: (DioError e) {
          ApUtils.showToast(context, ApLocalizations.dioError(context, e));
        },
        onSuccess: (GeneralResponse data) async {
          await CourseHelper.instance.checkLogin();
          _getCourse();
          FirebaseAnalyticsUtils.instance.logCaptchaErrorEvent(
            'course',
            CourseHelper.instance.captchaErrorCount,
          );
          CourseHelper.instance.captchaErrorCount = 0;
        },
      ),
    );
  }

  void _getCourse() async {
    courseData = await CourseHelper.instance.getCourseTable();
    courseData.save(courseCacheKey);
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
