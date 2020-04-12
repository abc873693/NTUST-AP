import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/scaffold/login_scaffold.dart';
import 'package:ntust_ap/api/course_helper.dart';
import 'package:ntust_ap/config/constants.dart';
import 'package:ntust_ap/pages/study/course_page.dart';
import 'package:ntust_ap/utils/ocr_utils.dart';
import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/general_response.dart';
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

  @override
  Widget build(BuildContext context) {
    app = ApLocalizations.of(context);
    return LoginScaffold(
      logoText: "T",
      forms: <Widget>[
        ApTextField(
          controller: _username,
          focusNode: usernameFocusNode,
          nextFocusNode: passwordFocusNode,
          labelText: app.username,
        ),
        ApTextField(
          obscureText: true,
          textInputAction: TextInputAction.next,
          controller: _password,
          focusNode: passwordFocusNode,
          nextFocusNode: validationCodeFocusNode,
          labelText: app.password,
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
              child: ApTextField(
                textInputAction: TextInputAction.send,
                controller: _validationCode,
                focusNode: validationCodeFocusNode,
                onSubmitted: (text) {
                  _login();
                },
                labelText: '驗證碼',
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextCheckBox(
              text: app.autoLogin,
              value: isAutoLogin,
              onChanged: (value) => setState(
                () {
                  isRememberPassword = value;
                  if (!isRememberPassword) isAutoLogin = false;
                  Preferences.setBool(Constants.PREF_AUTO_LOGIN, isAutoLogin);
                  Preferences.setBool(
                      Constants.PREF_REMEMBER_PASSWORD, isRememberPassword);
                },
              ),
            ),
            TextCheckBox(
              text: app.remember,
              value: isRememberPassword,
              onChanged: (value) => setState(
                () {
                  isRememberPassword = value;
                  if (!isRememberPassword) isAutoLogin = false;
                  Preferences.setBool(Constants.PREF_AUTO_LOGIN, isAutoLogin);
                  Preferences.setBool(
                      Constants.PREF_REMEMBER_PASSWORD, isRememberPassword);
                },
              ),
            ),
          ],
        ),
        ApButton(
          text: app.login,
          onPressed: _login,
        ),
      ],
    );
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

  void _getValidationCode() async {
    bodyBytes = await CourseHelper.instance.getValidationImage();
    setState(() {});
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _validationCode.text =
          await ValidateCodeUtils.extractByTfLite(bodyBytes: bodyBytes);
      setState(() {});
    }
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
            Navigator.of(context).pop(true);
          },
        ),
      );
    }
  }
}
