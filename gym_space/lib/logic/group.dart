import 'package:meta/meta.dart';

class Group {
  String admin;
  String name;
  String bio;
  String photoURL;
  String status;
  String startDate; //yyyy-mm-dd
  String endDate;
  String documentID;
  bool enabled = true;

  // Workout currentWorkout;
  // WorkoutPlan currentWorkoutPlan;

  List<String> likes = List();
  List<String> members = List();
  List<String> workoutPlans = List();
  Map<String, dynamic> challenges = Map();

  Group({
    @required this.admin,
    @required this.name,
    this.bio = "",
    this.photoURL = "",
    this.status = "",
    this.startDate = "",
    this.endDate = "",
    this.documentID,
    this.enabled,
    this.likes,
    this.members,
    this.workoutPlans,
    this.challenges,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'admin': admin,
      'name': name,
      'bio': bio,
      'photoURL': photoURL,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'enabled': enabled,
      'likes': likes ?? [],
      'members': members ?? [],
      'workoutPlans': workoutPlans ?? [],
      'challenges': challenges ?? Map(),
    };
  }

  static Group jsonToGroup(Map<String, dynamic> data) {
    return Group(
      admin: data['admin'],
      name: data['name'],
      bio: data['bio'],
      photoURL: data['photoURL'],
      status: data['status'],
      startDate: data['startDate'],
      endDate: data['endDate'],
      enabled: data['enabled'],
      likes: data['likes'].cast<String>(),
      members: data['members'].cast<String>(),
      workoutPlans: data['workoutPlans'].cast<String>(),
      challenges: data['challenges'].cast<String, dynamic>() ?? Map(),
    );
  }
}