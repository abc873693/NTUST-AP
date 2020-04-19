import 'package:ap_common/models/user_info.dart';
import 'package:ap_common/scaffold/user_info_scaffold.dart';
import 'package:ap_common_firbase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:ntust_ap/api/stu_helper.dart';

class UserInfoPage extends StatefulWidget {
  final UserInfo userInfo;

  const UserInfoPage({Key key, this.userInfo}) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  UserInfo userInfo;

  TextEditingController newEmail;

  @override
  void initState() {
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("UserInfoPage", "user_info_page.dart");
    userInfo = widget.userInfo;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return UserInfoScaffold(
      userInfo: userInfo,
      onRefresh: () async {
        this.userInfo = await StuHelper.instance.getUserInfo();
//        FA.setUserProperty('department', userInfo.department);
//        FA.logUserInfo(userInfo.department);
//        FA.setUserId(userInfo.id);
        setState(() {});
        return null;
      },
      actions: <Widget>[],
    );
  }
}
