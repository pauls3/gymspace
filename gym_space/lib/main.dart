import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'misc/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:GymSpace/database.dart';
import 'package:GymSpace/global.dart';
import 'package:GymSpace/page/login_page.dart';
import 'package:GymSpace/page/me_page.dart';

Future<void> main() async{
  final FirebaseApp app = await FirebaseApp.configure(
    name: 'gymspace',
    options: DatabaseConnections.database // our database 
  );
  
  // Paul: disabled to make messages work...
  
  // final Firestore firestore = Firestore(app: app);
  // firestore.settings(timestampsInSnapshotsEnabled: true);
  
  String _userID = await AuthSettings.auth.currentUser();
  Widget _defaultHome = LoginPage(auth: AuthSettings.auth, authStatus: AuthSettings.authStatus,);
  if (_userID != null) {
     DatabaseHelper.currentUserID = _userID;
    _defaultHome = MePage();
  }

  // await backupDB();

  // await DatabaseHelper.fixWorkoutPlans().then((count) => print('Fixed $count workout plans'));
  // await DatabaseHelper.fixUsers().then((count) => print('Fixed $count users'));
  // await DatabaseHelper.fixWorkouts().then((count) => print('Fixed $count workouts'));
  runApp(GymSpace(_defaultHome));
}

class GymSpace extends StatelessWidget {
  final Widget home;

  GymSpace(this.home);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    return MaterialApp(
      title: 'GymSpace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: GSColors.darkBlue,
        fontFamily: 'Lato'
      ),
      home: home,
    );
  }
}
