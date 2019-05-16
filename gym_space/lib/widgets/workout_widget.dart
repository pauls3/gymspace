import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/logic/workout.dart';
import 'package:GymSpace/global.dart';

class WorkoutWidget extends StatefulWidget {
  final Widget child;
  final Workout workout;

  WorkoutWidget({@required this.workout, Key key, this.child}) : super(key: key);

  _WorkoutWidgetState createState() => _WorkoutWidgetState();
}

class _WorkoutWidgetState extends State<WorkoutWidget> {
  Workout get workout => widget.workout;
  // String _newExericseName = "";
  bool _isExpanded = false;
  double height = 60;
  GlobalKey<FormState> _exerciseFormKey = GlobalKey<FormState>();

  void _updateWorkout(var exercise) async {
    DocumentSnapshot workoutDocument = await DatabaseHelper.getWorkoutSnapshot(workout.documentID);
    var list = workoutDocument.data['exercises'];
    // list[_newExericseName] = exercise;
    Firestore.instance.collection('workouts').document(workout.documentID).updateData(
      {'exercises': list});
    // var newValue = workoutDocument.data.update('exercises', list);
  }

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
                workout.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                )
              ),
              workout.description.isNotEmpty 
              ? Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  workout.description,
                  style: TextStyle(
                    height: 1.2
                    // fontSize: ,
                  ),
                ),
              )
              : Container(margin: EdgeInsets.only(bottom: 6),),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text(
                      '${workout.exercises.length} exercises',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}