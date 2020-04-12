import 'package:ntust_ap/api/course_helper.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/scaffold/course_scaffold.dart';
import 'package:flutter/material.dart';

class CoursePage extends StatefulWidget {
  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  CourseData courseData;

  CourseState _state = CourseState.loading;

  @override
  void initState() {
    _getCourse();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CourseScaffold(
      state: _state,
      courseData: courseData,
      onRefresh: () async {
        _getCourse();
      },
      isShowSearchButton: false,
    );
  }

  void _getCourse() async {
    courseData = CourseData.load('latest');
    if (courseData != null && courseData.courseTables.timeCode != null)
      setState(() => _state = CourseState.finish);
    courseData = await CourseHelper.instance.getCourseTable();
    courseData.save('latest');
    setState(() => _state = CourseState.finish);
  }
}
