import 'dart:async';
import 'package:GymSpace/logic/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:GymSpace/logic/auth.dart';

class AuthSettings {
  static Auth auth = Auth();
  static AuthStatus authStatus = AuthStatus.notLoggedIn;
}

class Defaults {
  static String userPhoto = 'lib/assets/userPhoto.png';
  static String userPhotoDB = 'https://firebasestorage.googleapis.com/v0/b/gymspace.appspot.com/o/userPhoto.png?alt=media&token=92f9628c-b00d-4cf0-9a72-1a1ed0cdd80c';
  static String groupPhoto = 'lib/assets/groupPhoto.png';
  static const int SHARE_KEY_LENGTH = 6;
}

class Errors {

}

class DatabaseHelper {
  // user 
  static String currentUserID = "";
  
  static Future<FirebaseUser> getCurrentUser() async {
    return await FirebaseAuth.instance.currentUser();
  }

  static Future<List<String>> getCurrentUserBuddies() async {
    DocumentSnapshot ds = await getUserSnapshot(currentUserID);
    List<String> buddies = ds.data['buddies'].cast<String>().toList();
    return buddies;
  }

  static Future<List<String>> getUserMedia(String userID) async {
    DocumentSnapshot ds = await getUserSnapshot(userID);
    List<String> media = ds.data['media'].cast<String>().toList();
    return media;
  }

  static Future<List<String>> getCurrentUserGroups() async {
    DocumentSnapshot ds = await getUserSnapshot(currentUserID);
    List<String> groups = ds.data['joinedGroups'].cast<String>().toList();
    List<String> revGroups = List();
    for (String id in groups) {
      await Firestore.instance.collection('groups').document(id).get().then((ds) {
        if (ds.exists) {
          revGroups.add(id);
        } else {
          updateUser(currentUserID, {'joinedGroups': FieldValue.arrayRemove([id])});
        }
      });
    }

    return revGroups;;
  }

  static Future<DocumentSnapshot> getUserSnapshot(String userID) async {
    return Firestore.instance.collection('users').document(userID).get();
  }

  static Future<List<User>> searchDBForUserByName(String name) async {
    String lowerName = name.toLowerCase();
    String searchName = lowerName.replaceRange(0, 1, name[0].toUpperCase());

    Query firstNameQuery = Firestore.instance.collection('users')
      .where('firstName', isGreaterThanOrEqualTo: searchName)
      .where('firstName', isLessThan: searchName + ' ');

    Query lastNameQuery = Firestore.instance.collection('users')
      .where('lastName', isGreaterThanOrEqualTo: searchName)
      .where('lastName', isLessThan: searchName + '');
    
    QuerySnapshot firstNameQuerySnap = await firstNameQuery.getDocuments();
    QuerySnapshot lastNameQuerySnap = await lastNameQuery.getDocuments();
    
    List<User> foundUsers = List();
    firstNameQuerySnap.documents.forEach((ds) {
      User user = User.jsonToUser(ds.data);
      user.documentID = ds.documentID;
      foundUsers.add(user);
    });
    
    lastNameQuerySnap.documents.forEach((ds) {
      if (!firstNameQuerySnap.documents.contains(ds)) {
        User user = User.jsonToUser(ds.data);
        user.documentID = ds.documentID;
        foundUsers.add(user);
      }
    });
    
    return foundUsers;
  }

  static Future<void> updateUser(String userID, Map<String, dynamic> data) {
    return Firestore.instance.collection('users').document(userID).updateData(data);
  }

  static Stream<DocumentSnapshot> getUserStreamSnapshot(String userID) {
    return Firestore.instance.collection('users').document(userID).snapshots();
  }

  // workouts
  static Future<DocumentSnapshot> getWorkoutPlanSnapshot(String workoutPlanID) async {
    return Firestore.instance.collection('workoutPlans').document(workoutPlanID).get();
  }

  static Stream getWorkoutPlanStreamSnapshot(String workoutPlanID) {
    return Firestore.instance.collection('workoutPlans').document(workoutPlanID).snapshots();
  }

  static Future<void> updateWorkoutPlan(String workoutPlanID, Map<String, dynamic> data) {
    return Firestore.instance.collection('workoutPlans').document(workoutPlanID).updateData(data);
  }

  static Future<DocumentSnapshot> getWorkoutSnapshot(String workoutID) async {
    return Firestore.instance.collection('workouts').document(workoutID).get();
  }

  static Stream getWorkoutStreamSnapshot(String workoutID) {
    return Firestore.instance.collection('workouts').document(workoutID).snapshots();
  }

  static Future<void> updateWorkout(String workoutID, Map<String, dynamic> data) {
    return Firestore.instance.collection('workouts').document(workoutID).updateData(data);
  }

  // challenges
  static Stream<DocumentSnapshot> getWeeklyChallenges(String challengeID) {
    return Firestore.instance.collection('challenges').document(challengeID).snapshots();
  }

  // groups
  static Future<DocumentSnapshot> getGroupSnapshot(String groupID) async {
    return Firestore.instance.collection('groups').document(groupID).get();
  }

  static Stream getGroupStreamSnapshot(String groupID) {
    return Firestore.instance.collection('groups').document(groupID).snapshots();
  }

  static Future<void> updateGroup(String groupID, Map<String, dynamic> data) async {
    return Firestore.instance.collection('groups').document(groupID).updateData(data);
  }

  // posts
  static Future<List<String>> fetchPosts() async {
    List<String> postIDS = List();
    DocumentSnapshot user = await getUserSnapshot(currentUserID);
    List<String> buddies = user.data['buddies'].cast<String>().toList();

    for (String buddyID in buddies) {
      await Firestore.instance.collection('posts').where('fromUser', isEqualTo: buddyID).getDocuments().then((queryResults) {
        postIDS.addAll(queryResults.documents.map((e) => e.documentID).toList());
      });
    }

    await Firestore.instance.collection('posts').where('fromUser', isEqualTo: currentUserID).getDocuments().then((queryResults) {
      postIDS.addAll(queryResults.documents.map((e) => e.documentID).toList());
    });
    return postIDS;
  }

  static Future<List<String>> fetchGroupPosts(String groupID) async {
    List<String> postIDs = List();
    // DocumentSnapshot group = await getGroupSnapshot(groupID);
    
    await Firestore.instance.collection('posts').where('fromGroup', isEqualTo: groupID).getDocuments()
      .then((queryResults) {
        postIDs.addAll(queryResults.documents.map((e) => e.documentID).toList());
      });

    return postIDs;
  }

  static Stream getPostStream(String postID) {
    return Firestore.instance.collection('posts').document(postID).snapshots();
  }

  static Future<void> updatePost(String postID, Map<String, dynamic> data) async {
    return Firestore.instance.collection('posts').document(postID).updateData(data);
  }

  static Future<DocumentSnapshot> findWorkoutPlanByKey(String shareKey) async {
    return await Firestore.instance.collection('workoutPlans').where('shareKey', isEqualTo: shareKey).getDocuments()
      .then((qs) {
        if(qs.documents.isEmpty) {
          print('Could not find workout with shareKey: $shareKey');
          return null;
        }
        
        return qs.documents[0];
      });
  }
}