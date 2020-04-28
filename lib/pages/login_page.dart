import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/scaffold/login_scaffold.dart';
import 'package:ap_common_firbase/utils/firebase_analytics_utils.dart';
import 'package:ntust_ap/api/stu_helper.dart';
import 'package:ntust_ap/config/constants.dart';
import 'package:ntust_ap/utils/captcha_utils.dart';
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
  final TextEditingController _month = TextEditingController();
  final TextEditingController _day = TextEditingController();
  final TextEditingController _idCard = TextEditingController();

  var isRememberPassword = true;
  var isAutoLogin = false;

  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _validationCodeFocusNode = FocusNode();
  final _monthFocusNode = FocusNode();
  final _dayFocusNode = FocusNode();
  final _idCardFocusNode = FocusNode();

  Uint8List bodyBytes;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("LoginPage", "login_page.dart");
    super.initState();
    _getPreference();
    _getValidationCode();
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
          focusNode: _usernameFocusNode,
          nextFocusNode: _passwordFocusNode,
          labelText: app.username,
        ),
        ApTextField(
          obscureText: true,
          textInputAction: TextInputAction.next,
          controller: _password,
          focusNode: _passwordFocusNode,
          nextFocusNode: _monthFocusNode,
          labelText: app.password,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: ApTextField(
                controller: _month,
                focusNode: _monthFocusNode,
                nextFocusNode: _dayFocusNode,
                keyboardType: TextInputType.number,
                labelText: app.birthMonth,
                maxLength: 2,
                onChanged: (text) {
                  if (text.length == 2) {
                    _monthFocusNode.unfocus();
                    FocusScope.of(context).requestFocus(_dayFocusNode);
                  }
                },
              ),
            ),
            SizedBox(width: 8.0),
            Expanded(
              child: ApTextField(
                keyboardType: TextInputType.number,
                controller: _day,
                focusNode: _dayFocusNode,
                nextFocusNode: _idCardFocusNode,
                labelText: app.birthDay,
                maxLength: 2,
                onChanged: (text) {
                  if (text.length == 2) {
                    _dayFocusNode.unfocus();
                    FocusScope.of(context).requestFocus(_idCardFocusNode);
                  }
                },
              ),
            ),
            SizedBox(width: 8.0),
            Expanded(
              flex: 2,
              child: ApTextField(
                controller: _idCard,
                focusNode: _idCardFocusNode,
                nextFocusNode: _validationCodeFocusNode,
                keyboardType: TextInputType.number,
                labelText: app.idCardLastCode,
                onChanged: (text) {
                  if (text.length == 4) {
                    _idCardFocusNode.unfocus();
                    FocusScope.of(context)
                        .requestFocus(_validationCodeFocusNode);
                  }
                },
              ),
            ),
          ],
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
    var password = '', month = '', day = '', idCard = '';
    if (isRememberPassword) {
      password = Preferences.getStringSecurity(Constants.PREF_PASSWORD, '');
      month = Preferences.getString(Constants.PREF_BIRTH_MONTH, '');
      day = Preferences.getString(Constants.PREF_BIRTH_DAY, '');
      idCard = Preferences.getStringSecurity(Constants.PREF_ID_CARD, '');
    }
    setState(() {
      _username.text = username;
      _password.text = password;
      _month.text = month;
      _day.text = day;
      _idCard.text = idCard;
    });
  }

  void _getValidationCode() async {
    bodyBytes = await StuHelper.instance.getValidationImage();
    setState(() {});
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _validationCode.text = await CaptchaUtils.extractByTfLite(
        bodyBytes: bodyBytes,
        type: SystemType.stu,
      );
      setState(() {});
    }
  }

  _login() async {
    if (_username.text.isEmpty ||
        _password.text.isEmpty ||
        _month.text.isEmpty ||
        _day.text.isEmpty ||
        _idCard.text.isEmpty) {
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
      StuHelper.instance.login(
        username: _username.text,
        password: _password.text,
        month: _month.text.length == 2 ? _month.text : '0${_month.text}',
        day: _day.text.length == 2 ? _day.text : '0${_day.text}',
        idCard: _idCard.text,
        validationCode: _validationCode.text,
        callback: GeneralCallback<GeneralResponse>(
          onError: (GeneralResponse e) async {
            Navigator.pop(context);
            var message = "";
            switch (e.statusCode) {
              case 4001:
                message = app.captchaError;
                break;
              case 4002:
                message = app.passwordError;
                break;
              case 4003:
                message = app.usernameError;
                break;
              case 4000:
              default:
                message = app.unknownError;
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
              await Preferences.setString(
                  Constants.PREF_BIRTH_MONTH, _month.text);
              await Preferences.setString(Constants.PREF_BIRTH_DAY, _day.text);
              await Preferences.setStringSecurity(
                  Constants.PREF_ID_CARD, _idCard.text);
            }
            Preferences.setBool(Constants.PREF_IS_OFFLINE_LOGIN, false);
            ApUtils.showToast(context, app.loginSuccess);
            Navigator.of(context).pop(true);
          },
        ),
      );
    }
  }
}
