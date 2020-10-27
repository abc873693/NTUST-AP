import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/callback/general_callback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ntust_ap/api/course_helper.dart';

enum SsoHelperState {
  loading,
  done,
  needValidateCaptcha,
  login,
}

class SsoHelper {
  static const LOGIN =
      'https://stuinfosys.ntust.edu.tw/NTUSTSSOServ/SSO/Login/CourseSelection';
  static const COURSE_HOME = 'https://courseselection.ntust.edu.tw/';
  static const COURSE_TABLE = '${COURSE_HOME}ChooseList/D01/D01';

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

  Future<void> login({
    @required String username,
    @required String password,
    String validationCode = '',
    GeneralCallback<GeneralResponse> callback,
  }) async {
    await webViewController.clearCache();
    await webViewController.evaluateJavascript(
        source:
            'document.getElementsByName("UserName")[0].value = "$username";document.getElementsByName("password")[0].value = "nick2000";document.getElementById("btnLogIn").click();');
    await webViewController.evaluateJavascript(
        source:
            'document.getElementsByName("Password")[0].value = "$password"');
    await webViewController.evaluateJavascript(
        source: 'document.getElementById("btnLogIn").click()');
    String url = await webViewController.getUrl();
    print('login = $url');
    callback.onSuccess(GeneralResponse.success());
  }

  Future<void> getCourseTable({
    GeneralCallback<CourseData> callback,
  }) async {
    await webViewController.loadUrl(url: COURSE_TABLE);
    await Future.delayed(Duration(seconds: 1));
    String html = await webViewController.getHtml();
    await CourseHelper.instance.getCourseTable(
      callback: callback,
      rawHtml: html,
    );
  }
}
