import 'package:encrypt/encrypt.dart';

class Constants {
  static bool get isInDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  static final key = Key.fromUtf8('l9r1W3wcsnJTayxCXwoFt62w1i4sQ5J9');
  static final iv = IV.fromUtf8('auc9OV5r0nLwjCAH');

  static const PREF_FIRST_ENTER_APP = "pref_first_enter_app";
  static const PREF_CURRENT_VERSION = "pref_current_version";
  static const PREF_REMEMBER_PASSWORD = "pref_remember_password";
  static const PREF_AUTO_LOGIN = "pref_auto_login";
  static const PREF_USERNAME = "pref_username";
  static const PREF_PASSWORD = "pref_password";

  static const PREF_COURSE_NOTIFY = "pref_course_notify";
  static const PREF_BUS_NOTIFY = "pref_bus_notify";
  static const PREF_COURSE_NOTIFY_DATA = "pref_course_notify_data";
  static const PREF_BUS_NOTIFY_DATA = "pref_bus_notify_data";
  static const PREF_COURSE_VIBRATE = "pref_course_vibrate";
  static const PREF_COURSE_VIBRATE_DATA = "pref_course_vibrate_data";
  static const PREF_COURSE_VIBRATE_USER_SETTING =
      "pref_course_vibrate_user_setting";
  static const PREF_DISPLAY_PICTURE = "pref_display_picture";
  static const PREF_SCORE_DATA = "pref_score_data";
  static const PREF_COURSE_DATA = "pref_course_data";
  static const PREF_LEAVE_DATA = "pref_leave_data";
  static const PREF_SEMESTER_DATA = "pref_semester_data";
  static const PREF_SCHEDULE_DATA = 'pref_schedule_datae';
  static const PREF_USER_INFO = "pref_user_info";
  static const PREF_BUS_RESERVATIONS_DATA = "pref_bus_reservevations_data";

  static const PREF_LANGUAGE_CODE = 'pref_language_code';
  static const PREF_THEME_MODE_INDEX = 'pref_theme_mode_index';

  static const PREF_AP_ENABLE = "pref_ap_enable";
  static const PREF_BUS_ENABLE = "pref_bus_enable";
  static const PREF_LEAVE_ENABLE = "pref_leave_enable";

  static const PREF_IS_OFFLINE_LOGIN = "pref_is_offline_login";
  static const PREF_IS_SHOW_COURSE_SEARCH_BUTTON =
      "pref_is_show_course_search_button";

  static const SCHEDULE_DATA = "schedule_data";
  static const ANDROID_APP_VERSION = "android_app_version";
  static const IOS_APP_VERSION = "ios_app_version";
  static const APP_VERSION = "app_version";
  static const NEW_VERSION_CONTENT_ZH = "new_version_content_zh";
  static const NEW_VERSION_CONTENT_EN = "new_version_content_en";
  static const NEWS_DATA = 'news_data_v2';
  static const DEFAULT_COURSE_SEMESTER_CODE = "default_course_semester_code";
  static const TIME_CODE_CONFIG = "time_code_config";

  static const TAG_STUDENT_PICTURE = "tag_student_picture";
  static const TAG_NEWS_PICTURE = "tag_news_picture";
  static const TAG_NEWS_ICON = "tag_news_icon";
  static const TAG_NEWS_TITLE = "tag_news_title";
}
