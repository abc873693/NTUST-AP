import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/ap_support_language.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/resources/ap_colors.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' as html;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:ntust_ap/config/constants.dart';

class CourseHelper {
  static const BASE_PATH = 'https://courseselection.ntust.edu.tw';

  static const LOGIN = '/Account/Login';
  static const VALIDATE_CODE = '/Account/GetValidateCode';
  static const COURSE = '/ChooseList/D01/D01';
  static const CHANGE_LANGUAGE = '/Home/SetCulture';
  static Dio dio;

  static CookieJar cookieJar;

  static CourseHelper _instance;

  static bool isLogin = false;

  static CourseHelper get instance {
    if (_instance == null) {
      _instance = CourseHelper();
      cookieJar = CookieJar();
      dio = Dio();
      dio.interceptors.add(CookieManager(cookieJar));
      cookieJar.loadForRequest(Uri.parse(BASE_PATH));
      _instance.setLanguage(
        Preferences.getString(
            Constants.PREF_LANGUAGE_CODE, ApSupportLanguage.zh.code),
      );
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
    list.add(Cookie('_culture', CourseHelper.instance.language(languageCode)));
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
    @required String validationCode,
    GeneralCallback<GeneralResponse> callback,
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
//      debugPrint(response.data);
      final rawHtml = response.data;
      GeneralResponse generalResponse;
      if (rawHtml.contains("圖形驗證碼錯誤")) {
        generalResponse = GeneralResponse(
          statusCode: 4001,
          message: 'Validate Code Error',
        );
      } else if (rawHtml.contains("密碼輸入錯誤")) {
        generalResponse = GeneralResponse(
          statusCode: 4002,
          message: 'Password Error',
        );
      } else if (rawHtml.contains("學號輸入錯誤")) {
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
          isLogin = true;
          print(callback?.onSuccess(GeneralResponse.success()).runtimeType);
//          callback?.onSuccess(GeneralResponse.success());
        } else
          callback?.onFailure(e);
      } else {
        callback?.onFailure(e);
      }
    }
  }

  Future<CourseData> getCourseTable() async {
    print('$BASE_PATH$COURSE');
    CourseData courseData = CourseData(
      courses: [],
      courseTables: CourseTables(),
    );
    var response = await dio.get(
      '$BASE_PATH$COURSE',
      options: Options(
        responseType: ResponseType.plain,
        contentType: Headers.acceptHeader,
      ),
    );
//    debugPrint(response.data);
    DateTime start = DateTime.now();
    final document = html.parse(response.data);
    final tBody = document.getElementsByTagName('tbody');
    debugPrint('tbody len = ${tBody.length}');
    if (tBody.length > 0) {
      //選課清單
      var trs = tBody[2].getElementsByTagName('tr');
      for (var i = 1; i < trs.length; i++) {
        final td = trs[i].getElementsByTagName('td');
        var title = parserText(td[1].text);
        courseData.courses.add(
          CourseDetail(
            code: td[0].text,
            title: title,
            units: td[2].text,
            required: td[3].getElementsByTagName('span').first.text,
            instructors: [td[4].text],
            times: '',
          ),
        );
      }
      courseData.courseTables.timeCode = [];
      trs = tBody[3].getElementsByTagName('tr');
//      debugPrint('trs len = ${trs.length}');
      final emptyLength = 13;
      for (var i = 1; i < trs.length; i++) {
        final td = trs[i].getElementsByTagName('td');
        final section = td[0].text;
        final times = td[1].text.split(String.fromCharCode(10));
        courseData.courseTables.timeCode.add(section);
        for (var weekIndex = 0;
            weekIndex < courseData.courseTables.weeks.length;
            weekIndex++) {
          if (td[weekIndex + 2].text.length > emptyLength)
            courseData.courseTables.weeks[weekIndex].add(
              parseCourse(
                title: td[weekIndex + 2].text,
                date: Date(
                  section: section,
                  startTime: times[1].trim().replaceAll('～', ''),
                  endTime: times[2].trim(),
                ),
                courseData: courseData,
              ),
            );
        }
      }
      for (var i = 0; i < courseData.courses.length; i++) {
        final courseDetail = courseData.courses[i];
        for (var weekIndex = 0;
            weekIndex < courseData.courseTables.weeks.length;
            weekIndex++) {
          List<String> sections = [];
          for (var course in courseData.courseTables.weeks[weekIndex]) {
            if (course.title == courseDetail.title) {
              sections.add(course.date.section);
              course.detailIndex = i;
            }
          }
          if (sections.length > 0) {
            courseDetail.times +=
                "(${ApLocalizations.instance.weekdaysCourse[weekIndex]}) ";
            sections.forEach((section) => courseDetail.times += '$section ');
          }
        }
      }
    }
    DateTime end = DateTime.now();
    print(
        'parse time = ${end.millisecondsSinceEpoch - start.millisecondsSinceEpoch} ms');
    return courseData;
  }

  String parserText(String text) {
    String newText = text.replaceAll(String.fromCharCode(10), '');
    newText = newText.replaceAll(' ', '');
    return newText;
  }

  Course parseCourse({
    String title,
    Date date,
    CourseData courseData,
  }) {
    var textList = title.split(String.fromCharCode(10));
    title = textList[1];
    title = title.replaceAll(' ', '');
    final course = Course(
      title: title,
      location: Location(
        building: parserText(textList[2]),
        room: '',
      ),
      date: date,
    );
    final index = courseData.findCourseDetail(course);
    if (index != -1) {
      course.instructors = courseData.courses[index].instructors;
      courseData.courses[index].location = course.location;
    }
    return course;
  }

  Future<void> checkLogin() async {
    print('$BASE_PATH$COURSE');
    var response = await dio.get(
      '$BASE_PATH',
      options: Options(
        responseType: ResponseType.plain,
      ),
    );
//    debugPrint(response.data);
  }
}
