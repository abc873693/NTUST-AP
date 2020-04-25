import 'dart:io';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/course_notify_data.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/scaffold/score_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common_firbase/utils/firebase_analytics_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:ntust_ap/api/course_helper.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/scaffold/course_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:ntust_ap/api/stu_helper.dart';
import 'package:ntust_ap/config/constants.dart';
import 'package:ntust_ap/utils/captcha_utils.dart';

class ScorePage extends StatefulWidget {
  @override
  _ScorePageState createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage>
    with SingleTickerProviderStateMixin {
  ApLocalizations ap;

  TabController _tabController;

  List<String> titles;

  Map<String, ScoreData> scoreDataMap;

  ScoreState _state = ScoreState.loading;

  int index = 0;

  ScoreData get scoreData =>
      (scoreDataMap != null && _tabController != null && titles != null)
          ? scoreDataMap[titles[index]]
          : null;

  @override
  void initState() {
    _getScore();
    FirebaseAnalyticsUtils.instance
        .setCurrentScreen("ScorePage", "score_page.dart");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return ScoreScaffold(
      bottom: scoreDataMap == null
          ? null
          : TabBar(
              isScrollable: true,
              controller: _tabController,
              tabs: [
                for (var semester in titles)
                  Tab(
                    text: semester,
                  )
              ],
              onTap: (index) {
                setState(() {
                  this.index = index;
                });
              },
            ),
      state: _state,
      scoreData: scoreData,
      middleTitle: ap.credits,
      isShowSearchButton: false,
      details: (scoreData == null || scoreData.detail == null)
          ? null
          : [
              '${ap.average}：${scoreData.detail.average ?? ''}',
              '${ap.classRank}：${scoreData.detail.classRank ?? ''}',
              '${ap.departmentRank}：${scoreData.detail.departmentRank ?? ''}',
            ],
      onRefresh: () async {
        _getScore();
      },
    );
  }

  void _getScore() async {
    scoreDataMap = await StuHelper.instance.getScore();
    if (mounted) {
      setState(() {
        if (scoreDataMap != null) {
          _tabController = TabController(
            vsync: this,
            length: scoreDataMap.length,
          );
          titles = scoreDataMap.keys.toList();
          _state = ScoreState.finish;
        } else
          _state = ScoreState.error;
      });
    }
  }
}
