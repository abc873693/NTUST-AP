import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ntust_ap/api/course_helper.dart';
import 'package:ntust_ap/api/stu_helper.dart';

enum SsoHelperState {
  loading,
  done,
  needValidateCaptcha,
  login,
  userInfo,
  course,
  scores,
}

class SsoHelper {
  static const LOGIN =
      'https://stuinfosys.ntust.edu.tw/NTUSTSSOServ/SSO/Login/CourseSelection';

  static const USER_INFO_BASE = 'https://stuinfosys.ntust.edu.tw/';
  static const USER_INFO_HOME = '${USER_INFO_BASE}StudentInformation/';
  static const USER_INFO_SCHOOL =
      '${USER_INFO_BASE}StudentInformation/Information';

  static const COURSE_HOME = 'https://courseselection.ntust.edu.tw/';
  static const COURSE_TABLE = '${COURSE_HOME}ChooseList/D01/D01';

  static const SCORE_HOME = 'https://stuinfosys.ntust.edu.tw/';
  static const SCORE_ALL =
      '${SCORE_HOME}StuScoreQueryServ/StuScoreQuery/DisplayAll';

  static SsoHelperState state = SsoHelperState.loading;

  static InAppWebViewController webViewController;

  static SsoHelper _instance;

  String username = '';
  String password = '';

  static SsoHelper get instance {
    if (_instance == null) {
      _instance = SsoHelper();
    }
    return _instance;
  }

  static GeneralCallback<GeneralResponse> loginCallback;

  static GeneralCallback<UserInfo> userInfoCallback;

  static GeneralCallback<CourseData> courseCallback;

  static GeneralCallback<Map<String, ScoreData>> scoreCallback;

  static Function(InAppWebViewController, String) onTitleChange =
      (controller, title) async {
    final path = await controller.getUrl();
    switch (state) {
      case SsoHelperState.loading:
        break;
      case SsoHelperState.done:
        break;
      case SsoHelperState.needValidateCaptcha:
        break;
      case SsoHelperState.login:
        if (path == SsoHelper.COURSE_HOME) {
          loginCallback.onSuccess(GeneralResponse.success());
          loginCallback = null;
        } else
          loginCallback.onError(GeneralResponse.unknownError());
        break;
      case SsoHelperState.course:
        if (path == SsoHelper.COURSE_TABLE) {
          String html = await webViewController.getHtml();
          await CourseHelper.instance.getCourseTable(
            callback: courseCallback,
            rawHtml: html,
          );
        } else
          courseCallback.onError(GeneralResponse.unknownError());
        break;
      case SsoHelperState.scores:
        if (path == SsoHelper.SCORE_ALL) {
          String html = await webViewController.getHtml();
          await StuHelper.instance.getScore(
            callback: scoreCallback,
            rawHtml: html,
          );
        } else
          scoreCallback.onError(GeneralResponse.unknownError());
        break;
      case SsoHelperState.userInfo:
        if (path == USER_INFO_SCHOOL) {
          String html = await webViewController.getHtml();
          await StuHelper.instance.getUserInfo(
            callback: userInfoCallback,
            rawHtml: html,
          );
        } else if (path == USER_INFO_HOME) {
          await webViewController.loadUrl(url: USER_INFO_SCHOOL);
        } else {
          userInfoCallback.onError(GeneralResponse.unknownError());
        }
        break;
    }
  };

  Future<void> login({
    @required String username,
    @required String password,
    GeneralCallback<GeneralResponse> callback,
  }) async {
    loginCallback = callback;
    state = SsoHelperState.login;
    await webViewController.clearCache();
    await webViewController.evaluateJavascript(
        source:
            'document.getElementsByName("UserName")[0].value = "$username";document.getElementsByName("password")[0].value = "nick2000";document.getElementById("btnLogIn").click();');
    await webViewController.evaluateJavascript(
        source:
            'document.getElementsByName("Password")[0].value = "$password"');
    await webViewController.evaluateJavascript(
        source: 'document.getElementById("btnLogIn").click()');
    await Future.delayed(Duration(seconds: 5));
    loginCallback?.onError(GeneralResponse.unknownError());
  }

  Future<void> getUserInfo({
    GeneralCallback<UserInfo> callback,
  }) async {
    userInfoCallback = callback;
    state = SsoHelperState.userInfo;
    await webViewController.loadUrl(url: USER_INFO_SCHOOL);
  }

  Future<void> getCourseTable({
    GeneralCallback<CourseData> callback,
  }) async {
    courseCallback = callback;
    state = SsoHelperState.course;
    await webViewController.loadUrl(url: COURSE_TABLE);
  }

  Future<void> getScores({
    GeneralCallback<Map<String, ScoreData>> callback,
  }) async {
    scoreCallback = callback;
    state = SsoHelperState.scores;
    await webViewController.loadUrl(url: SCORE_ALL);
  }
}
