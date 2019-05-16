import 'package:GymSpace/global.dart';
import 'package:GymSpace/logic/workout_plan.dart';
import 'package:flutter/material.dart';

class WorkoutPlanWidget extends StatelessWidget {
  String get currentUserID => DatabaseHelper.currentUserID;
  final WorkoutPlan workoutPlan;

  const WorkoutPlanWidget({
    @required this.workoutPlan,
    Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)
        ),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: <Widget>[
              Text(
                workoutPlan.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  workoutPlan.description,
                  style: TextStyle(
                    height: 1.2
                    // fontSize: ,
                  ),
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text(
                      '${workoutPlan.workouts.length} workouts',
                    ),
                    FutureBuilder(
                      future: DatabaseHelper.getUserSnapshot(workoutPlan.author),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text('By: ');
                        }

                        return Container(
                          child: Text('By: ${snapshot.data.data['firstName']} ${snapshot.data.data['lastName']}'),
                        );
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}