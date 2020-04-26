import 'dart:io';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/general_response.dart';
import 'package:ap_common/pages/about_us_page.dart';
import 'package:ap_common/pages/news/news_content_page.dart';
import 'package:ap_common/pages/open_source_page.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/home_page_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/ap_drawer.dart';
import 'package:ap_common/widgets/default_dialog.dart';
import 'package:ap_common_firbase/constants/fiirebase_constants.dart';
import 'package:ap_common_firbase/utils/firebase_analytics_utils.dart';
import 'package:ap_common_firbase/utils/firebase_remote_config_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ntust_ap/pages/school_map_page.dart';
import 'package:package_info/package_info.dart';
import 'package:ap_common/models/new_response.dart';
import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/widgets/yes_no_dialog.dart';
import 'package:ntust_ap/api/github_helper.dart';
import 'package:ntust_ap/api/stu_helper.dart';
import 'package:ntust_ap/config/constants.dart';
import 'package:ntust_ap/pages/setting_page.dart';
import 'package:ntust_ap/pages/study/score_page.dart';
import 'package:ntust_ap/pages/user_info_page.dart';
import 'package:ntust_ap/resourses/ap_assets.dart';
import 'package:ntust_ap/utils/app_localizations.dart';
import 'package:ntust_ap/utils/captcha_utils.dart';
import 'package:ntust_ap/widgets/share_data_widget.dart';

import 'study/course_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  static const String routerName = "/home";

  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<HomePageScaffoldState> _homeKey =
      GlobalKey<HomePageScaffoldState>();

  AppLocalizations app;
  ApLocalizations ap;

  HomeState state = HomeState.loading;

  var validationCode;

  bool isLogin = false;

  UserInfo userInfo;

  List<News> newsList = [];

  bool isStudyExpanded = false;

  TextStyle get _defaultStyle => TextStyle(
        color: ApTheme.of(context).grey,
        fontSize: 16.0,
      );

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("HomePage", "home_page.dart");
    _getAllNews();
    if (Preferences.getBool(Constants.PREF_AUTO_LOGIN, false))
      _login();
    else
      _checkLoginState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _checkUpdate();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    ap = ApLocalizations.of(context);
    return HomePageScaffold(
      key: _homeKey,
      isLogin: isLogin,
      state: state,
      title: app.appName,
      actions: <Widget>[
        IconButton(
          icon: Icon(ApIcon.info),
          onPressed: _showInformationDialog,
        ),
      ],
      onImageTapped: (News news) {
        ApUtils.pushCupertinoStyle(
          context,
          NewsContentPage(news: news),
        );
        String message = news.description.length > 12
            ? news.description
            : news.description.substring(0, 12);
        FirebaseAnalyticsUtils.instance.logAction(
          'news_image',
          'click',
          message: message,
        );
      },
      drawer: ApDrawer(
        userInfo: userInfo,
        widgets: <Widget>[
          ExpansionTile(
            initiallyExpanded: isStudyExpanded,
            onExpansionChanged: (bool) {
              setState(() => isStudyExpanded = bool);
            },
            leading: Icon(
              ApIcon.collectionsBookmark,
              color: isStudyExpanded
                  ? ApTheme.of(context).blueAccent
                  : ApTheme.of(context).grey,
            ),
            title: Text(ap.courseInfo, style: _defaultStyle),
            children: <Widget>[
              DrawerSubItem(
                icon: ApIcon.classIcon,
                title: ap.course,
                page: CoursePage(),
                needLogin: !isLogin,
              ),
              DrawerSubItem(
                icon: ApIcon.assignment,
                title: ap.score,
                page: ScorePage(),
                needLogin: !isLogin,
              ),
            ],
          ),
          DrawerItem(
            icon: ApIcon.map,
            title: ap.schoolMap,
            page: SchoolMapPage(),
          ),
          DrawerItem(
            icon: ApIcon.face,
            title: ap.about,
            page: AboutUsPage(
              assetImage: ImageAssets.ntust,
              githubName: 'NKUST-ITC',
              email: 'abc873693@gmail.com',
              appLicense: app.aboutOpenSourceContent,
              fbFanPageId: '735951703168873',
              fbFanPageUrl: 'https://www.facebook.com/NKUST.ITC/',
              githubUrl: 'https://github.com/NKUST-ITC',
              logEvent: (name, value) =>
                  FirebaseAnalyticsUtils.instance.logAction(name, value),
              setCurrentScreen: () => FirebaseAnalyticsUtils.instance
                  .setCurrentScreen("AboutUsPage", "about_us_page.dart"),
              actions: <Widget>[
                IconButton(
                  icon: Icon(ApIcon.codeIcon),
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => OpenSourcePage(
                          setCurrentScreen: () =>
                              FirebaseAnalyticsUtils.instance.setCurrentScreen(
                                  "OpenSourcePage", "open_source_page.dart"),
                        ),
                      ),
                    );
                    FirebaseAnalyticsUtils.instance
                        .logAction('open_source', 'click');
                  },
                )
              ],
            ),
          ),
          DrawerItem(
            icon: ApIcon.settings,
            title: ap.settings,
            page: SettingPage(),
          ),
          if (isLogin)
            ListTile(
              leading: Icon(
                ApIcon.powerSettingsNew,
                color: ApTheme.of(context).grey,
              ),
              onTap: () {
                Navigator.of(context).pop();
                isLogin = false;
                Preferences.setBool(Constants.PREF_AUTO_LOGIN, false);
                //TODO clear session
                _checkLoginState();
              },
              title: Text(
                ap.logout,
                style: _defaultStyle,
              ),
            ),
        ],
        onTapHeader: () {
          if (isLogin) {
            if (userInfo != null) {
              Navigator.of(context).pop();
              ApUtils.pushCupertinoStyle(
                context,
                UserInfoPage(
                  userInfo: userInfo,
                ),
              );
            }
          } else {
            Navigator.of(context).pop();
            _showLoginPage();
          }
        },
      ),
      newsList: newsList,
      onTabTapped: onTabTapped,
      bottomNavigationBarItems: [
        BottomNavigationBarItem(
          icon: Icon(ApIcon.classIcon),
          title: Text(ap.course),
        ),
        BottomNavigationBarItem(
          icon: Icon(ApIcon.assignment),
          title: Text(ap.score),
        ),
      ],
    );
  }

  void onTabTapped(int index) async {
    setState(() {
      switch (index) {
        case 0:
          if (isLogin)
            ApUtils.pushCupertinoStyle(context, CoursePage());
          else
            ApUtils.showToast(context, ap.notLoginHint);
          break;
        case 1:
          if (isLogin)
            ApUtils.pushCupertinoStyle(context, ScorePage());
          else
            ApUtils.showToast(context, ap.notLoginHint);
          break;
      }
    });
  }

  _getAllNews() async {
    GitHubHelper.instance.getNews(
      callback: GeneralCallback(
        onError: (GeneralResponse e) {
          setState(() => state = HomeState.error);
        },
        onFailure: (DioError e) {
          setState(() => state = HomeState.error);
          ApUtils.handleDioError(context, e);
        },
        onSuccess: (List<News> data) {
          newsList = data;
          setState(() {
            if (newsList == null || newsList.length == 0)
              state = HomeState.empty;
            else {
              newsList.sort((a, b) {
                return b.weight.compareTo(a.weight);
              });
              state = HomeState.finish;
            }
          });
        },
      ),
    );
  }

  void _showInformationDialog() {
    FirebaseAnalyticsUtils.instance.logAction('news_rule', 'click');
    showDialog(
      context: context,
      builder: (BuildContext context) => YesNoDialog(
        title: ap.newsRuleTitle,
        contentWidget: RichText(
          text: TextSpan(
            style: TextStyle(color: ApTheme.of(context).grey, fontSize: 16.0),
            children: [
              TextSpan(
                  text: '${ap.newsRuleDescription1}',
                  style: TextStyle(fontWeight: FontWeight.normal)),
              TextSpan(
                  text: '${ap.newsRuleDescription2}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text: '${ap.newsRuleDescription3}',
                  style: TextStyle(fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        leftActionText: ap.cancel,
        rightActionText: ap.contactFansPage,
        leftActionFunction: () {},
        rightActionFunction: () {
          ApUtils.launchFbFansPage(context, Constants.FANS_PAGE_ID);
          FirebaseAnalyticsUtils.instance
              .logAction('contact_fans_page', 'click');
        },
      ),
    );
  }

  void _checkLoginState() async {
    await Future.delayed(Duration(microseconds: 50));
    if (isLogin) {
      _homeKey.currentState.hideSnackBar();
    } else {
      _homeKey.currentState
          .showSnackBar(
            text: ApLocalizations.of(context).notLogin,
            actionText: ApLocalizations.of(context).login,
            onSnackBarTapped: _showLoginPage,
          )
          .closed
          .then(
        (SnackBarClosedReason reason) {
          _checkLoginState();
        },
      );
    }
  }

  _login() async {
    var start = DateTime.now();
    var username = Preferences.getString(Constants.PREF_USERNAME, '');
    var password = Preferences.getStringSecurity(Constants.PREF_PASSWORD, '');
    var month = Preferences.getString(Constants.PREF_BIRTH_MONTH, '');
    var day = Preferences.getString(Constants.PREF_BIRTH_DAY, '');
    var idCard = Preferences.getStringSecurity(Constants.PREF_ID_CARD, '');
    var end = DateTime.now();
    print(
        'load preference time = ${end.millisecondsSinceEpoch - start.millisecondsSinceEpoch} ms');
    var bodyBytes = await StuHelper.instance.getValidationImage();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      validationCode = await CaptchaUtils.extractByTfLite(
        bodyBytes: bodyBytes,
        type: SystemType.stu,
      );
    }
    StuHelper.instance.login(
      username: username,
      password: password,
      month: month,
      day: day,
      idCard: idCard,
      validationCode: validationCode,
      callback: GeneralCallback(
        onError: (GeneralResponse e) async {
          if (e.statusCode == 4001) {
            _login();
          }
        },
        onFailure: (DioError e) {
          ApUtils.showToast(context, ApLocalizations.dioError(context, e));
        },
        onSuccess: (GeneralResponse data) async {
          _homeKey.currentState.showBasicHint(text: ap.loginSuccess);
          _getUserInfo();
          setState(() {
            ShareDataWidget.of(context).data.username = username;
            ShareDataWidget.of(context).data.password = password;
            isLogin = true;
          });
        },
      ),
    );
  }

  _getUserInfo() async {
    StuHelper.instance.getUserInfo(
      callback: GeneralCallback(
        onFailure: (DioError e) {},
        onError: (GeneralResponse e) {},
        onSuccess: (UserInfo data) {
          setState(() {
            userInfo = data;
          });
          FirebaseAnalyticsUtils.instance.setUserProperty(
            FirebaseConstants.STUDENT_ID,
            userInfo.id,
          );
          FirebaseAnalyticsUtils.instance.setUserId(
            userInfo.id,
          );
        },
      ),
    );
  }

  _checkUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await Future.delayed(Duration(milliseconds: 50));
    var currentVersion =
        Preferences.getString(Constants.PREF_CURRENT_VERSION, '');
    if (currentVersion != packageInfo.buildNumber) {
      DefaultDialog.showUpdateContent(
        context,
        "v${packageInfo.version}\n"
        "${app.updateNoteContent}",
      );
      Preferences.setString(
        Constants.PREF_CURRENT_VERSION,
        packageInfo.buildNumber,
      );
    }
    if (!Constants.isInDebugMode) {
      VersionInfo versionInfo =
          await FirebaseRemoteConfigUtils.getVersionInfo();
      if (versionInfo != null)
        ApUtils.showNewVersionDialog(
          context: context,
          newVersionCode: versionInfo.code,
          iOSAppId: '1508879766',
          defaultUrl: 'https://www.facebook.com/NKUST.ITC/',
          newVersionContent: versionInfo.content,
          appName: AppLocalizations.of(context).appName,
        );
    }
  }

  _showLoginPage() async {
    var result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => LoginPage(),
      ),
    );
    if (result ?? false) {
      if (state != HomeState.finish) {
        _getAllNews();
      }
      _getUserInfo();
      isLogin = true;
      _homeKey.currentState.hideSnackBar();
    } else {
      _checkLoginState();
    }
  }
}
