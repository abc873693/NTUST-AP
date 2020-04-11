import 'dart:io';
import 'dart:typed_data';

import 'package:ntust_ap/api/course_helper.dart';
import 'package:ntust_ap/config/constants.dart';
import 'package:ntust_ap/pages/course_page.dart';
import 'package:ntust_ap/utils/ocr_utils.dart';
import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/general_response.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ap_common/widgets/progress_dialog.dart';

class LoginPage extends StatefulWidget {
  static const String routerName = "/login";

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  ApLocalizations app;

  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _validationCode = TextEditingController();

  var isRememberPassword = true;
  var isAutoLogin = false;

  FocusNode usernameFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode validationCodeFocusNode = FocusNode();

  Uint8List bodyBytes;

  @override
  void initState() {
    super.initState();
    _getPreference();
    _getValidationCode();
    //TODO get system storage permission
  }

  @override
  void dispose() {
    super.dispose();
  }

  _editTextStyle() => TextStyle(
      color: Colors.white, fontSize: 18.0, decorationColor: Colors.white);

  @override
  Widget build(BuildContext context) {
    app = ApLocalizations.of(context);
    return OrientationBuilder(
      builder: (_, orientation) {
        return Scaffold(
          backgroundColor: ApTheme.of(context).blue,
          resizeToAvoidBottomPadding: orientation == Orientation.portrait,
          body: Container(
            alignment: Alignment(0, 0),
            padding: EdgeInsets.symmetric(horizontal: 30.0),
            child: orientation == Orientation.portrait
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.min,
                    children: _renderContent(orientation),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _renderContent(orientation),
                  ),
          ),
        );
      },
    );
  }

  _renderContent(Orientation orientation) {
    List<Widget> list = orientation == Orientation.portrait
        ? <Widget>[
            Center(
              child: Text(
                'T',
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: orientation == Orientation.portrait ? 30.0 : 0.0),
          ]
        : <Widget>[
            Expanded(
              child: Text(
                'T',
                style: TextStyle(
                  fontSize: 120,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: orientation == Orientation.portrait ? 30.0 : 0.0),
          ];
    List<Widget> listB = <Widget>[
      TextField(
        maxLines: 1,
        controller: _username,
        textInputAction: TextInputAction.next,
        focusNode: usernameFocusNode,
        onSubmitted: (text) {
          usernameFocusNode.unfocus();
          FocusScope.of(context).requestFocus(passwordFocusNode);
        },
        decoration: InputDecoration(
          labelText: app.username,
        ),
        style: _editTextStyle(),
      ),
      TextField(
        obscureText: true,
        maxLines: 1,
        textInputAction: TextInputAction.next,
        controller: _password,
        focusNode: passwordFocusNode,
        onSubmitted: (text) {
          passwordFocusNode.unfocus();
        },
        decoration: InputDecoration(
          labelText: app.password,
        ),
        style: _editTextStyle(),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onTap: _getValidationCode,
            child: Container(
              width: 160.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: (bodyBytes != null)
                    ? Image.memory(
                        bodyBytes,
                        fit: BoxFit.cover,
                      )
                    : Container(),
              ),
            ),
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              maxLines: 1,
              textInputAction: TextInputAction.send,
              controller: _validationCode,
              focusNode: validationCodeFocusNode,
              onSubmitted: (text) {
                validationCodeFocusNode.unfocus();
                _login();
              },
              decoration: InputDecoration(
                labelText: '驗證碼',
              ),
              style: _editTextStyle(),
            ),
          ),
        ],
      ),
      SizedBox(height: 8.0),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
//          GestureDetector(
//            child: Row(
//              mainAxisAlignment: MainAxisAlignment.end,
//              children: <Widget>[
//                Theme(
//                  data: ThemeData(
//                    unselectedWidgetColor: Colors.white,
//                  ),
//                  child: Checkbox(
//                    activeColor: Colors.white,
//                    checkColor: ApTheme.of(context).blue,
//                    value: isAutoLogin,
//                    onChanged: _onAutoLoginChanged,
//                  ),
//                ),
//                Text(app.autoLogin, style: TextStyle(color: Colors.white))
//              ],
//            ),
//            onTap: () => _onAutoLoginChanged(!isAutoLogin),
//          ),
          GestureDetector(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: Colors.white,
                  ),
                  child: Checkbox(
                    activeColor: Colors.white,
                    checkColor: ApTheme.of(context).blue,
                    value: isRememberPassword,
                    onChanged: _onRememberPasswordChanged,
                  ),
                ),
                Text(app.remember, style: TextStyle(color: Colors.white))
              ],
            ),
            onTap: () => _onRememberPasswordChanged(!isRememberPassword),
          ),
        ],
      ),
      SizedBox(height: 8.0),
      Container(
        width: double.infinity,
        child: RaisedButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(30.0),
            ),
          ),
          padding: EdgeInsets.all(14.0),
          onPressed: () {
            //TODO FA
            _login();
          },
          color: Colors.white,
          child: Text(
            app.login,
            style: TextStyle(color: ApTheme.of(context).blue, fontSize: 18.0),
          ),
        ),
      ),
    ];
    if (orientation == Orientation.portrait) {
      list.addAll(listB);
    } else {
      list.add(Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: listB)));
    }
    return list;
  }

  _onRememberPasswordChanged(bool value) async {
    setState(() {
      isRememberPassword = value;
      if (!isRememberPassword) isAutoLogin = false;
      Preferences.setBool(Constants.PREF_AUTO_LOGIN, isAutoLogin);
      Preferences.setBool(Constants.PREF_REMEMBER_PASSWORD, isRememberPassword);
    });
  }

  _onAutoLoginChanged(bool value) async {
    setState(() {
      isAutoLogin = value;
      isRememberPassword = isAutoLogin;
      Preferences.setBool(Constants.PREF_AUTO_LOGIN, isAutoLogin);
      Preferences.setBool(Constants.PREF_REMEMBER_PASSWORD, isRememberPassword);
    });
  }

  _getPreference() async {
    isRememberPassword =
        Preferences.getBool(Constants.PREF_REMEMBER_PASSWORD, true);
    var username = Preferences.getString(Constants.PREF_USERNAME, '');
    var password = '';
    if (isRememberPassword) {
      password = Preferences.getStringSecurity(Constants.PREF_PASSWORD, '');
    }
    setState(() {
      _username.text = username;
      _password.text = password;
    });
  }

  _login() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      ApUtils.showToast(context, app.doNotEmpty);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => WillPopScope(
          child: ProgressDialog(app.logining),
          onWillPop: () async {
            return false;
          },
        ),
        barrierDismissible: false,
      );
      Preferences.setString(Constants.PREF_USERNAME, _username.text);
      CourseHelper.instance.login(
        username: _username.text,
        password: _password.text,
        validationCode: _validationCode.text,
        callback: GeneralCallback<GeneralResponse>(
          onError: (GeneralResponse e) {
            Navigator.pop(context);
            var message = "";
            print(e.statusCode);
            switch (e.statusCode) {
              case 4001:
                message = "驗證碼錯誤";
                break;
              case 4002:
                message = "密碼輸入錯誤";
                break;
              case 4003:
                message = "學號輸入錯誤";
                break;
              case 4000:
              default:
                message = app.unknown;
                break;
            }
            ApUtils.showToast(context, message);
          },
          onFailure: (DioError e) {
            Navigator.pop(context);
            ApUtils.showToast(context, ApLocalizations.dioError(context, e));
          },
          onSuccess: (GeneralResponse data) async {
            Navigator.pop(context);
            Preferences.setString(Constants.PREF_USERNAME, _username.text);
            if (isRememberPassword) {
              await Preferences.setStringSecurity(
                Constants.PREF_PASSWORD,
                _password.text,
              );
            }
            Preferences.setBool(Constants.PREF_IS_OFFLINE_LOGIN, false);
            ApUtils.showToast(context, app.loginSuccess);
            await CourseHelper.instance.checkLogin();
            ApUtils.pushCupertinoStyle(
              context,
              CoursePage(),
            );
          },
        ),
      );
    }
  }

  void _getValidationCode() async {
    bodyBytes = await CourseHelper.instance.getValidationImage();
    setState(() {});
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _validationCode.text =
          await ValidateCodeUtils.extractByTfLite(bodyBytes: bodyBytes);
      setState(() {});
    }
  }
}
