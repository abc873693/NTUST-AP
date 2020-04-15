import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/ap_support_language.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' as html;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:ntust_ap/config/constants.dart';

class StuHelper {
  static const BASE_PATH = 'https://stuinfo8.ntust.edu.tw';

  static const LOGIN = '/ntust_stu/stu.aspx';
  static const VALIDATE_CODE = '/ntust_stu/VCode.aspx';
  static const MENU = '/ntust_stu/stu_menu.aspx';
  static const CHANGE_LANGUAGE = '/Home/SetCulture';
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

  Future<UserInfo> getUserInfo() async {
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
      return UserInfo(
        id: tds[1].text,
        name: tds[3].text,
        className: tds[5].text,
      );
    }
    return null;
  }
}
