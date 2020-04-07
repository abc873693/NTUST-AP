import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' as html;
import 'package:cookie_jar/cookie_jar.dart';

class CourseHelper {
  static const BASE_PATH = 'https://courseselection.ntust.edu.tw';

  static const LOGIN = '/Account/Login';
  static const VALIDATE_CODE = '/Account/GetValidateCode';

  static Dio dio;

  static CookieJar cookieJar;

  static CourseHelper _instance;

  static CourseHelper get instance {
    if (_instance == null) {
      _instance = CourseHelper();
      cookieJar = CookieJar();
      dio = Dio();
      cookieJar
          .loadForRequest(Uri.parse("https://courseselection.ntust.edu.tw/"));
    }
    return _instance;
  }

  Future<Uint8List> getValidationImage() async {
//    if (Platform.isAndroid) {
//      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
//          (client) {
//        client.badCertificateCallback =
//            (X509Certificate cert, String host, int port) => true;
//        return client;
//      };
//    }
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
    @required String validationCode,
    GeneralCallback callback,
  }) async {
    try {
      final option = Options(
        responseType: ResponseType.plain,
        contentType: Headers.formUrlEncodedContentType,
      );
      final token = await getToken();
      var response = await dio.post(
        '$BASE_PATH$LOGIN',
        options: option,
        data: {
          '__RequestVerificationToken': token,
          'UserName': username,
          'Password': password,
          'VerifyCode': validationCode,
        },
      );
      debugPrint(response.data);
      return GeneralResponse.success();
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE && e.response.statusCode == 302) {
        print(e.response.data);
        print(e.response.isRedirect);
        if (e.response.data.toString().contains('Error.html'))
          callback?.onError(
            GeneralResponse(
              statusCode: 401,
              message: 'Fail',
            ),
          );
        else if (e.response.data.toString().contains('Object moved'))
          return GeneralResponse.success();
        else
          callback?.onFailure(e);
      } else {
        callback?.onFailure(e);
      }
    }
    return null;
  }
}
