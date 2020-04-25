import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/ap_support_language.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
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

  static StuHelper get instance {
    if (_instance == null) {
      _instance = StuHelper();
      cookieJar = CookieJar();
      dio = Dio();
      dio.interceptors.add(CookieManager(cookieJar));
      if (Platform.isAndroid) {
        (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
            (client) {
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        };
      }
      cookieJar.loadForRequest(Uri.parse(BASE_PATH));
//      _instance.setLanguage(
//        Preferences.getString(
//            Constants.PREF_LANGUAGE_CODE, ApSupportLanguage.zh.code),
//      );
    }
    return _instance;
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

  Future<void> login({
    @required String username,
    @required String password,
    @required String month,
    @required String day,
    @required String idCard,
    @required String validationCode,
    GeneralCallback<GeneralResponse> callback,
  }) async {
    try {
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
        generalResponse = GeneralResponse(
          statusCode: 4001,
          message: 'Validate Code Error',
        );
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
      } else
        generalResponse = GeneralResponse(
          statusCode: 4000,
          message: 'Unkown Error',
        );
      callback?.onError(generalResponse);
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
          print(callback?.onSuccess(GeneralResponse.success()).runtimeType);
//          callback?.onSuccess(GeneralResponse.success());
        } else
          callback?.onFailure(e);
      } else {
        callback?.onFailure(e);
      }
    }
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
  }) async {
    try {
      var response = await dio.get(
        '$BASE_PATH$MENU',
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
      final document = html.parse(response.data);
      final tBody = document.getElementsByTagName('tbody');
      debugPrint('tbody len = ${tBody.length}');
      if (tBody.length > 0) {
        var tds = tBody[1].getElementsByTagName('td');
        return callback?.onSuccess(
          UserInfo(
            id: tds[1].text,
            name: tds[3].text,
            className: tds[5].text,
          ),
        );
      }
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
  }) async {
    try {
      var response = await dio.get(
        '$BASE_PATH$SCORE',
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
      final document = html.parse(response.data);
      Map<String, ScoreData> scoreDataMap = Map();
      final currentScore = document.getElementById('Datagrid4');
      var currentScores = List<Score>();
      if (currentScore != null) {
        var trs = currentScore.getElementsByTagName('tr');
        for (var i = 1; i < trs.length; i++) {
          var tds = trs[i].getElementsByTagName('td');
//          print(tds[2].text);
          currentScores.add(
            Score(
              courseNumber: tds[1].text,
              title: tds[2].text,
              units: tds[3].text,
              middleScore: tds[3].text,
              finalScore: tds[4].text.length > 5 ? '' : tds[4].text,
              remark: tds[5].text + tds[6].text,
            ),
          );
        }
      }
      final pastScore = document.getElementById('DataGrid1');
      if (pastScore != null) {
        var trs = pastScore.getElementsByTagName('tr');
        for (var i = trs.length - 1; i > 0; i--) {
          var tds = trs[i].getElementsByTagName('td');
          String semester = tds[1].text.trim();
          if (scoreDataMap[semester] == null)
            scoreDataMap[semester] = ScoreData(
              scores: [],
              detail: Detail(),
            );
          scoreDataMap[semester].scores.add(
                Score(
                  courseNumber: tds[2].text,
                  title: tds[3].text,
                  units: tds[4].text,
                  middleScore: tds[4].text,
                  finalScore: tds[5].text.length > 5 ? '' : tds[5].text,
                  remark: tds[6].text + tds[7].text,
                ),
              );
        }
      }
      final scoreDetail = document
          .getElementById('score_list')
          .getElementsByTagName('font')
          .first;
      if (scoreDetail != null) {
        final ranks = scoreDetail.innerHtml.split('<br>');
        final exp = RegExp(r"(.+)學年度第(.+)學期學期.+\((.+)\)排名為第(.+)名，學期平均成績為：(.+)");
        for (var rank in ranks.reversed) {
          if (rank.length == 0) continue;
          final data = exp.allMatches(rank).first;
          if (data != null) {
            final semester = '${data.group(1).trim()}${data.group(2).trim()}';
            if (scoreDataMap[semester] == null)
              scoreDataMap[semester] = ScoreData(
                scores: [],
                detail: Detail(),
              );
            scoreDataMap[semester].detail
              ..average = double.parse(data.group(5).trim());
            final type = data.group(3).trim();
            if (type == '系')
              scoreDataMap[semester].detail.departmentRank =
                  data.group(4).trim();
            else if (type == '班')
              scoreDataMap[semester].detail.classRank = data.group(4).trim();
          }
        }
        if (currentScores.length != 0 &&
            scoreDataMap.values.last.scores.length == 0)
          scoreDataMap.values.last.scores = currentScores;
      }
      return callback == null
          ? scoreDataMap
          : callback?.onSuccess(scoreDataMap);
    } on DioError catch (e) {
      callback?.onFailure(e);
    } on Exception catch (e) {
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
    return null;
  }
}
