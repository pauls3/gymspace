import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  loggedIn,
  notLoggedIn
}

abstract class BaseAuth {
  Future<String> signInWithEmailAndPassword(String email, String password);
  Future<String> createUserWithEmailAndPassword(String email, String password);
  Future<String> currentUser();
  Future<void> signOut();
}

class Auth implements BaseAuth{
  // General Login
  Future<String> signInWithEmailAndPassword(String email, String password) async {
    FirebaseUser user = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    return user == null ? null : user.uid;
  }

  // Creating a new User Login through email
  Future<String> createUserWithEmailAndPassword(String email, String password) async{
    FirebaseUser user = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    return user == null ? null : user.uid;
  }

  // Check if logged in already or not
  Future<String> currentUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    return user == null ? null : user.uid;
  }

  // Signing out the User
  Future<void> signOut() async {
    return FirebaseAuth.instance.signOut();
  }
}