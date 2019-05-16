import 'dart:async';
import 'package:GymSpace/global.dart';
import 'package:GymSpace/logic/workout.dart';
import 'package:GymSpace/logic/workout_plan.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:GymSpace/widgets/workout_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WorkoutPlanPage extends StatefulWidget {
  final Widget child;
  final WorkoutPlan workoutPlan;

  WorkoutPlanPage({
    @required this.workoutPlan, Key key, this.child
  }) : super(key: key);

  @override
  _WorkoutPlanPageState createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  WorkoutPlan get workoutPlan => widget.workoutPlan;
  final GlobalKey<FormState> _workoutFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _exerciseFormKey = GlobalKey<FormState>();
  String get currentUserID => DatabaseHelper.currentUserID;
  List<String> deadWorkoutIds = List();

  
  void _addPressed() {
    Workout newWorkout = Workout();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Container(
          // margin: MediaQuery.of(context).viewInsets,
          child: Column(
            // mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                child: _buildForm(newWorkout),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FlatButton(
                      onPressed: () {
                        if (_workoutFormKey.currentState.validate()) {
                          setState(() {
                            _workoutFormKey.currentState.save();
                            print("Adding Workout to database");
                            _addWorkoutToDB(newWorkout);
                            Navigator.pop(context);});
                          }
                      },
                      child: Text(
                        'Create',
                        style: TextStyle(
                          color: GSColors.lightBlue,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                )
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _addWorkoutToDB(Workout workout) async {
    workout.author = currentUserID;
    await Firestore.instance.collection('workouts').add(workout.toJSON()).then((ds) async {
        print('-> Added ' + workout.name + ' to the database with id: ' + ds.documentID);
        await DatabaseHelper.updateWorkoutPlan(workoutPlan.documentID, {'workouts': FieldValue.arrayUnion([ds.documentID])})
          .then((_) => Fluttertoast.showToast(msg: 'Added workout to workout plan'));
      });
  }

  Widget _buildForm(Workout workout) {
    return Form(
      key: _workoutFormKey,
      child: Column(
        children: <Widget>[
          TextFormField( // name
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: "e.g. Back Day",
              labelText: "Workout Name",
            ),
            onSaved: (name) => workout.name = name,
            validator: (value) => value.isEmpty ? "This field cannot be empty" : null,
          ),
          TextFormField( // description
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: "e.g. This workout consists of exercises for back and biceps. The main motion is pulling.",
              labelText: "Description",
            ),
            onSaved: (desc) => workout.description = desc,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseForm(Map<String, String> exercise) {
    return Form(
      key: _exerciseFormKey,
      child: Column(
        children: <Widget>[
          TextFormField( // name
            textCapitalization: TextCapitalization.words,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: "e.g. Lat Pulldowns",
              labelText: "Exercise Name",
            ),
            onSaved: (name) => exercise['name'] = name,
            validator: (value) => value.isEmpty ? "This field cannot be empty" : null,
          ),
          TextFormField( // muscleGroup
            keyboardType: TextInputType.number,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: "e.g. 3",
              labelText: "Sets",
            ),
            onSaved: (sets) => exercise['sets'] = sets,
          ),
          TextFormField( // muscleGroup
            keyboardType: TextInputType.number,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: "e.g. 10",
              labelText: "Reps",
            ),
            onSaved: (reps) => exercise['reps'] = reps,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GSColors.darkBlue,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: PageHeader(
          fontsize: 16,
          title: workoutPlan.name, 
          backgroundColor: Colors.white,
          titleColor: GSColors.darkBlue,
        ),
      ),
      body: _buildWorkoutsList(),
      floatingActionButton: workoutPlan.author == currentUserID ? FloatingActionButton(
        onPressed: _addPressed,
        backgroundColor: GSColors.purple,
        child: Icon(Icons.add),
      ) : Container(),
    );
  }

  Widget _buildWorkoutsList() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: StreamBuilder(
        stream: DatabaseHelper.getWorkoutPlanStreamSnapshot(workoutPlan.documentID),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }

          List<String> workoutIDs = snapshot.data.data['workouts'].cast<String>().toList();
          deadWorkoutIds = List();
          return ListView.builder(
            itemCount: workoutIDs.length,
            itemBuilder: (context, i) {
              return StreamBuilder(
                stream: DatabaseHelper.getWorkoutStreamSnapshot(workoutIDs[i]),
                builder: (context, workoutSnap) {
                  if (deadWorkoutIds.isNotEmpty) {
                    deadWorkoutIds.forEach((id) => print('$id not found in the DB. Must have been recently deleted. Removing from list.'));
                    DatabaseHelper.updateWorkoutPlan(workoutPlan.documentID, {'workouts': FieldValue.arrayRemove(deadWorkoutIds)});
                  }

                  if (!workoutSnap.hasData) {
                    return Container();
                  }

                  if (!workoutSnap.data.exists) {
                    deadWorkoutIds.add(workoutSnap.data.documentID);
                    return Container();
                  }

                  Workout workout = Workout.jsonToWorkout(workoutSnap.data.data);
                  workout.documentID = workoutSnap.data.documentID;
                  return _buildWorkoutItem(workout);
                }
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkoutItem(Workout workout) {
    return Container(
      // margin: EdgeInsets.all(6),
      child: InkWell(
        onTap: () => _workoutTapped(workout),
        onLongPress: () => _workoutLongPressed(workout),
        child: WorkoutWidget(workout: workout,),
      ),
    );
  }

  void _workoutLongPressed(Workout workout) {
    if (workoutPlan.author != currentUserID)
      return; 

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child:  Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FlatButton.icon(
                textColor: GSColors.red,
                icon: Icon(Icons.delete, color: GSColors.red,),
                label: Text('Delete'),
                onPressed: () => _deletePressed(workout),
              ),
              FlatButton.icon(
                textColor: GSColors.purple,
                icon: Icon(Icons.edit,),
                label: Text('Edit'),
                onPressed: () => _editPressed(workout),
              )
            ],
          )
        );
      },
    );
  }

  void _deletePressed(Workout workout) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text('Are you sure?'),
              FlatButton.icon(
                textColor: GSColors.red,
                icon: Icon(Icons.cancel),
                label: Text('No'),
                onPressed: () {Navigator.pop(context);},
              ),
              FlatButton.icon(
                textColor: GSColors.green,
                icon: Icon(Icons.check),
                label: Text('Yes'),
                onPressed: () => _deleteWorkout(workout),
              ),
            ],
          ),
        );
      }
    );
  }

  void _editPressed(Workout workout) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          child: Container(
            // margin: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              // mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  child: _buildForm(workout),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FlatButton(
                        onPressed: () {
                          if (_workoutFormKey.currentState.validate()) {
                            setState(() {
                              _workoutFormKey.currentState.save();
                              DatabaseHelper.updateWorkout(workout.documentID, {'name': workout.name, 'description': workout.description})
                                .then((_) => Fluttertoast.showToast(msg: 'Workout updated'));
                              Navigator.pop(context);});
                          }
                        },
                        child: Text(
                          'Update',
                          style: TextStyle(
                            color: GSColors.lightBlue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Future<void> _deleteWorkout(Workout workout) async {
    Navigator.pop(context);
    await DatabaseHelper.updateWorkoutPlan(workoutPlan.documentID, {'workouts': FieldValue.arrayRemove([workout.documentID])});
    await Firestore.instance.collection('workouts').document(workout.documentID).delete();
    Fluttertoast.showToast(msg: 'Deleted Workout');
  }

  void _workoutTapped(Workout workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          // margin: MediaQuery.of(context).viewInsets,
          child: Container(
            margin: EdgeInsets.only(top: 20),
            child: Stack(
              children: <Widget>[
                ListView.separated(
                  itemCount: workout.exercises.length,
                  itemBuilder: (context, i) {
                    Map<String, String> exercise = workout.exercises[i].cast<String, String>();
                    
                    return Container(
                      margin: EdgeInsets.only(left: 4,),
                      child: ListTile(
                        // onTap: () => _exerciseTapped(workout, exercise),
                        onLongPress: () => workoutPlan.author == currentUserID ? _exerciseLongPressed(workout.documentID, exercise) : {}, 
                        title: Text(exercise['name'], style: TextStyle(fontSize: 16)),
                        subtitle: Container(
                          margin: EdgeInsets.only(left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('${exercise['sets']} sets', style: TextStyle(fontSize: 14)),
                              Text('${exercise['reps']} reps', style: TextStyle(fontSize: 14))
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, i) {
                    return Divider();
                  },
                ),
                workoutPlan.author == currentUserID ? Container(
                  margin: EdgeInsets.only(right: 20),
                  alignment: Alignment.topRight,
                  child: FlatButton.icon(
                    textColor: GSColors.lightBlue,
                    icon: Icon(Icons.add),
                    label: Text('Add'),
                    onPressed: () => workoutPlan.author == currentUserID ? _addExerciseTapped(workout) : {}
                  ),
                ) : Container(),
              ],
            ),
          ),
        );
      }
    );
  }

  void _exerciseLongPressed(String workoutID, Map exercise) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text('Remove exercise?'),
              FlatButton.icon(
                textColor: GSColors.red,
                label: Text('Remove'),
                icon: Icon(Icons.remove),
                onPressed: () => _removeExercise(workoutID, exercise),
              )
            ],
          ),
        );
      }
    );
  }

  void _removeExercise(String workoutID, Map<String, String> exercise) {
    DatabaseHelper.updateWorkout(workoutID, {'exercises': FieldValue.arrayRemove([exercise])})
      .then((_) {
        Fluttertoast.showToast(msg: 'Removed exercise');
        Navigator.pop(context);
        Navigator.pop(context);
      });
  }

  void _addExerciseTapped(Workout workout) {
    Map<String, String> exercise = Map();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          margin: MediaQuery.of(context).viewInsets,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: _buildExerciseForm(exercise),
              ),
              Flexible(
                child: FlatButton.icon(
                  textColor: GSColors.green,
                  label: Text('Add Exercise'),
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (_exerciseFormKey.currentState.validate()) {
                      _exerciseFormKey.currentState.save();
                      DatabaseHelper.updateWorkout(workout.documentID, {'exercises': FieldValue.arrayUnion([exercise])})
                        .then((_) {
                          Fluttertoast.showToast(msg: 'Added exercise to workout');
                          Navigator.pop(context);
                          Navigator.pop(context);
                        });
                    }
                  },
                )
              )
            ],
          )
        );
      }
    );
  }

  Future<void> _removeWorkoutFromDB(Workout workout) async {
    // may need to query to get ALL workout plans that contain this workout
    print('Removing workout from the workout plan');
    await Firestore.instance.collection('workoutPlans').document(workoutPlan.documentID)
      .updateData({'workouts': FieldValue.arrayRemove([workout.documentID])})
      .then((_) => print('-> Removed workout from workout plan'))
      .catchError((e) => print('-> Failed to remove workout from workout plan.\nError: $e'));

    // if (false) { // This feature is currently off. Before removing, must check to see if the current user is the author of the workout
    //   await Firestore.instance.collection('workouts').document(workout.documentID).delete()
    //     .then((_) => print('-> Removed workout from collection.'))
    //     .catchError((e) => print('-> Failed to remove workout from colection.\nError: $e'));
    // }

    workoutPlan.workouts.remove(workout);
  }
}