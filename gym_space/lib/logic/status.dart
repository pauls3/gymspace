// // This file needs to be updated 

// import 'package:flutter/material.dart';
// import 'package:GymSpace/page/login_page.dart';
// import 'auth.dart';
// import 'package:GymSpace/home.dart';

// enum AuthStatus {
//   loggedIn,
//   notLoggedIn
// }

// class StatusPage extends StatefulWidget {
//   StatusPage({this.auth});
//   final BaseAuth auth;
//   @override
//   State<StatefulWidget> createState() => new _StatusPageState();
// }
// class _StatusPageState extends State<StatusPage> {
//   // Status of checking if user is logged in
//   AuthStatus authStatus = AuthStatus.notLoggedIn;

//   initState(){
//     super.initState();
//     // Check if the user is initiallized logged in the app
//     widget.auth.currentUser().then((userID){
//       setState((){
//         authStatus = userID == null ? AuthStatus.notLoggedIn : AuthStatus.loggedIn;
//       });
//     });
//   }  

//   void _loggedIn() {
//     setState(() {
//       authStatus = AuthStatus.loggedIn;
//     });
//   }

//   void _loggedOut() {
//     setState(() {
//       authStatus = AuthStatus.notLoggedIn;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     switch(authStatus) {
//       case AuthStatus.loggedIn:
//         return new Home(
//           auth: widget.auth,
//           onLoggedOut: _loggedOut,
//         );
//       // case AuthStatus.notLoggedIn:
//       //   return new LoginPage(
//       //     auth: widget.auth,
//       //     onLoggedIn: _loggedIn,
//       //   );
//       default: 
//         return new Home(
//           auth: widget.auth,
//           onLoggedOut: _loggedOut,
//         );
//     }
//   }
// }