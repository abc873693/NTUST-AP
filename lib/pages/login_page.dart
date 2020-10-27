import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/scaffold/login_scaffold.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:ntust_ap/api/sso_helper.dart';
import 'package:ntust_ap/api/stu_helper.dart';
import 'package:ntust_ap/config/constants.dart';
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

  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _validationCodeFocusNode = FocusNode();

  Uint8List bodyBytes;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("LoginPage", "login_page.dart");
    super.initState();
    _getPreference();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = ApLocalizations.of(context);
    return LoginScaffold(
      logoSource: "T",
      logoMode: LogoMode.text,
      forms: <Widget>[
        ApTextField(
          controller: _username,
          focusNode: _usernameFocusNode,
          nextFocusNode: _passwordFocusNode,
          labelText: app.username,
        ),
        ApTextField(
          obscureText: true,
          textInputAction: TextInputAction.send,
          controller: _password,
          focusNode: _passwordFocusNode,
          labelText: app.password,
          onSubmitted: (_) {
            _login();
          },
        ),
        if (kIsWeb || !(Platform.isAndroid || Platform.isIOS))
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
                  focusNode: _validationCodeFocusNode,
                  onSubmitted: (text) {
                    _login();
                  },
                  labelText: app.captcha,
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
                  isAutoLogin = value;
                  isRememberPassword = isAutoLogin;
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
    bodyBytes = await StuHelper.instance.getValidationImage();
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
      SsoHelper.instance.login(
        username: _username.text,
        password: _password.text,
        validationCode: _validationCode.text,
        callback: GeneralCallback<GeneralResponse>(
          onError: (GeneralResponse e) async {
            Navigator.pop(context);
            Navigator.pop(context, false);
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
            Navigator.of(context).pop(true);
          },
        ),
      );
    }
  }
}
