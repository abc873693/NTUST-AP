import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/course_notify_data.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common_firbase/utils/firebase_analytics_utils.dart';
import 'package:ntust_ap/api/course_helper.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/scaffold/course_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:ntust_ap/api/stu_helper.dart';

class CoursePage extends StatefulWidget {
  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  ApLocalizations ap;

  CourseData courseData;
  CourseNotifyData notifyData;

  CourseState _state = CourseState.loading;

  String customStateHint;
  String customHint;

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
    ap = ApLocalizations.of(context);
    return CourseScaffold(
      state: _state,
      customStateHint: customStateHint,
      customHint: customHint,
      courseData: courseData,
      onRefresh: () async {
        if (CourseHelper.isLogin)
          _getCourse();
        else
          _login();
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

  Function(DioError) get dioError => (DioError e) {
        setState(() {
          if (courseData != null) {
            customHint = '${ap.offlineCourse}';
            _state = CourseState.finish;
          } else {
            customStateHint = ApLocalizations.dioError(context, e);
            _state = CourseState.error;
          }
        });
      };

  void _login() async {
    CourseHelper.instance.login(
      username: StuHelper.instance.username,
      password: StuHelper.instance.password,
      callback: GeneralCallback(
        onError: (GeneralResponse e) async {
          if (e.statusCode == 4001) {
            setState(() {
              _state = CourseState.error;
            });
          } else {
            setState(() {
              _state = CourseState.custom;
              customStateHint = ApLocalizations.of(context).onlySupportInSchool;
            });
          }
        },
        onFailure: dioError,
        onSuccess: (GeneralResponse data) async {
          await CourseHelper.instance.checkLogin();
          _getCourse();
        },
      ),
    );
  }

  void _getCourse() async {
    CourseHelper.instance.getCourseTable(
      callback: GeneralCallback(
        onSuccess: (CourseData data) {
          if (mounted) {
            setState(() {
              if (data != null && data.courseTables.timeCode != null) {
                courseData = data;
                _state = CourseState.finish;
                courseData.save(courseCacheKey);
              } else if (courseData != null) {
                customHint = '${ap.offlineCourse}';
                _state = CourseState.custom;
              } else
                _state = CourseState.error;
            });
          }
        },
        onFailure: dioError,
        onError: (GeneralResponse e) {
          setState(() {
            _state = CourseState.error;
          });
        },
      ),
    );
  }
}
