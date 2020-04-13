import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/models/new_response.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' as html;
import 'package:cookie_jar/cookie_jar.dart';

class GitHubHelper {
  static const BASE_PATH = 'https://gist.githubusercontent.com';

  static const NEWS =
      '/abc873693/c18531b5664e5eeb2d3dbc1ad6cb102e/raw/ntust_news.json';

  static Dio dio;

  static CookieJar cookieJar;

  static GitHubHelper _instance;

  static GitHubHelper get instance {
    if (_instance == null) {
      _instance = GitHubHelper();
      cookieJar = CookieJar();
      dio = Dio();
      dio.interceptors.add(CookieManager(cookieJar));
      cookieJar.loadForRequest(Uri.parse(BASE_PATH));
    }
    return _instance;
  }

  Future<void> getNews({
    @required GeneralCallback<List<News>> callback,
  }) async {
    try {
      final option = Options(
        responseType: ResponseType.plain,
      );
      var response = await dio.get(
        '$BASE_PATH$NEWS',
        options: option,
      );
      final rawHtml = response.data;
      callback?.onSuccess(NewsResponse.fromRawJson(rawHtml).data);
    } on DioError catch (e) {
      callback?.onFailure(e);
    }
  }
}
