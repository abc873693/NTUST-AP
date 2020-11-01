import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/score_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:ntust_ap/api/sso_helper.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.score),
        backgroundColor: ApTheme.of(context).blue,
        bottom: _tabController == null
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
              ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    switch (_state) {
      case ScoreState.loading:
        return Container(
            child: CircularProgressIndicator(), alignment: Alignment.center);
      case ScoreState.error:
      case ScoreState.empty:
        return FlatButton(
          onPressed: () {
            _getScore();
          },
          child: HintContent(
            icon: ApIcon.assignment,
            content:
                _state == ScoreState.error ? ap.clickToRetry : ap.scoreEmpty,
          ),
        );
      case ScoreState.offlineEmpty:
        return HintContent(
          icon: ApIcon.classIcon,
          content: ap.noOfflineData,
        );
      default:
        return TabBarView(
          controller: _tabController,
          children: <Widget>[
            for (var scoreData in scoreDataMap.values)
              ScoreContent(
                scoreData: scoreData,
                middleTitle: ap.credits,
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
              )
          ],
        );
    }
  }

  void _getScore() async {
    SsoHelper.instance.getScores(
      callback: GeneralCallback(
        onFailure: (DioError e) {
          setState(() {
            _state = ScoreState.error;
          });
        },
        onSuccess: (Map<String, ScoreData> data) {
          scoreDataMap = data;
          if (mounted) {
            setState(() {
              if (scoreDataMap != null) {
                if (scoreDataMap.length == 0)
                  _state = ScoreState.empty;
                else
                  _state = ScoreState.finish;
                _tabController = TabController(
                  vsync: this,
                  length: scoreDataMap.length,
                );
                titles = scoreDataMap.keys.toList();
              } else
                _state = ScoreState.error;
            });
          }
        },
        onError: (GeneralResponse e) {
          setState(() {
            _state = ScoreState.error;
          });
        },
      ),
    );
  }
}
