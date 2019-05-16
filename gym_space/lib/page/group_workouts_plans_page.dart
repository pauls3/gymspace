import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:flutter/material.dart';

class GroupWorkoutPlansPage extends StatefulWidget {
  GroupWorkoutPlansPage({Key key}) : super(key: key);

  _GroupWorkoutPlansPageState createState() => _GroupWorkoutPlansPageState();
}

class _GroupWorkoutPlansPageState extends State<GroupWorkoutPlansPage> {

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: PageHeader(
        title: 'Group Workout Plans',
        backgroundColor: Colors.white,
        titleColor: GSColors.darkBlue,

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GSColors.darkBlue,
      appBar: _buildAppBar(),
      body: Container(),
    );
  }
}