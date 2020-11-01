import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/ap_support_language.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' as html;
import 'package:cookie_jar/cookie_jar.dart';

class StuHelper {
  static const BASE_PATH = 'https://stuinfo8.ntust.edu.tw';

  static const LOGIN = '/ntust_stu/stu.aspx';
  static const VALIDATE_CODE = '/ntust_stu/VCode.aspx';
  static const MENU = '/ntust_stu/stu_menu.aspx';
  static const SCORE = '/ntust_stu/Query_Score.aspx';

  static Dio dio;

  static CookieJar cookieJar;

  static StuHelper _instance;

  String username = '';
  String password = '';
  String birthMonth = '';
  String birthDay = '';
  String idCardLast = '';

  int captchaErrorCount = 0;

  static StuHelper get instance {
    if (_instance == null) {
      _instance = StuHelper();
      dio = Dio();
      if (Platform.isAndroid) {
        (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
            (client) {
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        };
      }
      initCookiesJar();
//      _instance.setLanguage(
//        Preferences.getString(
//            Constants.PREF_LANGUAGE_CODE, ApSupportLanguage.zh.code),
//      );
    }
    return _instance;
  }

  static initCookiesJar() {
    cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse(BASE_PATH));
  }

  void logout() {
    initCookiesJar();
  }

  String language(String languageCode) {
    switch (languageCode) {
      case ApSupportLanguageConstants.EN:
        return 'en-US';
      case ApSupportLanguageConstants.ZH:
      default:
        return 'zh-TW';
    }
  }

  void setLanguage(String languageCode) {
    var list = cookieJar.loadForRequest(Uri.parse(BASE_PATH));
    list.add(Cookie('_culture', StuHelper.instance.language(languageCode)));
    cookieJar.saveFromResponse(Uri.parse(BASE_PATH), list);
  }

  Future<Uint8List> getValidationImage() async {
    var response = await dio.get(
      '$BASE_PATH$VALIDATE_CODE',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  Future<String> getToken() async {
    var response = await dio.get(
      '$BASE_PATH$LOGIN',
      options: Options(
        responseType: ResponseType.plain,
      ),
    );
    final document = html.parse(response.data);
    final input = document.getElementsByTagName('input');
    return input[0].attributes['value'];
  }

  Future<GeneralResponse> login({
    @required String username,
    @required String password,
    @required String month,
    @required String day,
    @required String idCard,
    String validationCode,
    GeneralCallback<GeneralResponse> callback,
  }) async {
    try {
      var bodyBytes;
      final option = Options(
        responseType: ResponseType.plain,
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:55.0) Gecko/20100101 Firefox/55.0',
        },
      );
      var response = await dio.post(
        '$BASE_PATH$LOGIN',
        options: option,
        data: {
//          '__RequestVerificationToken': token,
          '__EVENTTARGET': '',
          '__EVENTARGUMENT': '',
          '__VIEWSTATE': 'dDwtMzQ5OTkwMzk3Ozs+isl6ygjrAXhHXt/V5pMOqMJOcyk=',
          '__VIEWSTATEGENERATOR': '7D63B901',
          'studentno': username,
          'idcard': idCard,
          'DropMonth': month,
          'DropDay': day,
          'password': password,
          'code_box': validationCode,
          'Button1': "登入系統"
        },
      );
//      debugPrint(response.data);
      final rawHtml = response.data;
      GeneralResponse generalResponse;
      if (rawHtml.contains("檢核碼輸入錯誤")) {
        captchaErrorCount++;
        generalResponse = GeneralResponse(
          statusCode: 4001,
          message: 'Validate Code Error',
        );
        if (captchaErrorCount < 10 &&
            (!kIsWeb && (Platform.isAndroid || Platform.isIOS))) {
          return await login(
            username: username,
            password: password,
            month: month,
            day: day,
            idCard: idCard,
            callback: callback,
          );
        }
      } else if (rawHtml.contains("密碼輸入錯誤")) {
        generalResponse = GeneralResponse(
          statusCode: 4002,
          message: 'Password Error',
        );
      } else if (rawHtml.contains("資料輸入錯誤，請確定您輸入的各項資料是否正確")) {
        generalResponse = GeneralResponse(
          statusCode: 4003,
          message: 'Username Error',
        );
      } else {
        generalResponse = GeneralResponse(
          statusCode: 4000,
          message: 'Unkown Error',
        );
      }
      callback?.onError(generalResponse);
      _logErrorCount();
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE && e.response.statusCode == 302) {
        print(e.response.data);
        print(e.response.isRedirect);
        String rawHtml = e.response.data.toString();
        if (rawHtml.contains('Error.html'))
          callback?.onError(
            GeneralResponse(
              statusCode: 4000,
              message: 'Unkown Error',
            ),
          );
        else if (e.response.data.toString().contains('Object moved')) {
          this.username = username;
          this.password = password;
          this.birthMonth = month;
          this.birthDay = day;
          this.idCardLast = idCard;
          _logErrorCount();
          return callback != null
              ? callback?.onSuccess(GeneralResponse.success())
              : GeneralResponse.success();
        } else
          callback?.onFailure(e);
      } else {
        callback?.onFailure(e);
      }
      _logErrorCount();
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      _logErrorCount()();
      throw e;
    }
    return null;
  }

  _logErrorCount() async {
    FirebaseAnalyticsUtils.instance.logCaptchaErrorEvent(
      'stu',
      captchaErrorCount,
    );
    captchaErrorCount = 0;
  }

  Future<void> checkLogin() async {
    print('$BASE_PATH$MENU');
    var response = await dio.get(
      '$BASE_PATH',
      options: Options(
        responseType: ResponseType.plain,
      ),
    );
    debugPrint(response.data);
  }

  Future<UserInfo> getUserInfo({
    GeneralCallback<UserInfo> callback,
    String rawHtml,
  }) async {
    try {
      final document = html.parse(rawHtml);
      return callback?.onSuccess(
        UserInfo(
          id: document.getElementById('StudentNo').attributes['value'],
          name: document.getElementById('StudentName').attributes['value'],
          className: document.getElementById('Department').attributes['value'],
        ),
      );
    } on DioError catch (e) {
      callback?.onFailure(e);
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }

  Future<Map<String, ScoreData>> getScore({
    GeneralCallback<Map<String, ScoreData>> callback,
    String rawHtml,
  }) async {
    try {
      final document = html.parse(rawHtml);
      Map<String, ScoreData> scoreDataMap = Map();
      final tbodys = document.getElementsByTagName('tbody');
      final pastScore = tbodys[1];
      if (pastScore != null) {
        var trs = pastScore.getElementsByTagName('tr');
        for (var i = 0; i < trs.length; i++) {
          var tds = trs[i].getElementsByTagName('td');
          String semester = tds[1].text.trim();
          if (scoreDataMap[semester] == null)
            scoreDataMap[semester] = ScoreData(
              scores: [],
              detail: Detail(),
            );
          scoreDataMap[semester].scores.add(
                Score(
                  courseNumber: tds[2].text.trim(),
                  title: tds[3].text.trim(),
                  units: tds[4].text.trim(),
                  middleScore: tds[4].text.trim(),
                  finalScore:
                      tds[5].text.trim().length > 5 ? '' : tds[5].text.trim(),
                  remark: tds[6].text.trim() + tds[7].text.trim(),
                ),
              );
        }
      }
      final scoreDetail = tbodys[0];
      if (scoreDetail != null) {
        var trs = scoreDetail.getElementsByTagName('tr');
        for (var i = 0; i < trs.length; i++) {
          var tds = trs[i].getElementsByTagName('td');
          final semester = tds[0].text.trim();
          print(tds[0].text.trim());
          final detail = Detail(
            classRank: tds[1].text.trim(),
            departmentRank: tds[2].text.trim(),
            average: double.parse(tds[3].text.trim()),
          );
          if (scoreDataMap[semester] == null)
            scoreDataMap[semester] = ScoreData(
              scores: [],
              detail: detail,
            );
          else
            scoreDataMap[semester].detail = detail;
        }
      }
      return callback == null
          ? scoreDataMap
          : callback?.onSuccess(scoreDataMap);
    } on DioError catch (e) {
      callback?.onFailure(e);
    } catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }
}
