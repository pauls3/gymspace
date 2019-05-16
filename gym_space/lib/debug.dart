import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:random_string/random_string.dart';

import 'global.dart';

Future<void> backup(String collection, String path) async {
  File collectionFile = File('$path/$collection.json');
  var collectionDocuments = await Firestore.instance.collection(collection).getDocuments();
  for (DocumentSnapshot ds in collectionDocuments.documents) {
    await collectionFile.writeAsString('DOCID: ${ds.documentID}\n${ds.data}\n', mode: FileMode.append);
  }
  print('Saved $collection to $path/$collection.json');
}

Future<void> backupDB() async {
  final directory = await getApplicationDocumentsDirectory();
  var path = directory.path;

  await backup('challenges', path);
  await backup('groups', path);
  await backup('messages', path);
  await backup('posts', path);
  await backup('users', path);
  await backup('workoutPlans', path);
  await backup('workouts', path);
}


// FIX OUTDATED WORKOUTPLANS
  Future<int> fixWorkoutPlans() async {
    int fixed = 0;
    await Firestore.instance.collection('workoutPlans').getDocuments()
      .then((qs) async {
        for (DocumentSnapshot ds in qs.documents) {
          if (!ds.data.containsKey('shareKey')) {
            await Firestore.instance.collection('workoutPlans').document(ds.documentID).updateData({
              'shareKey': randomAlphaNumeric(Defaults.SHARE_KEY_LENGTH)
            }).then((_) => fixed++);
          }

          if (!ds.data.containsKey('private')) {
            await Firestore.instance.collection('workoutPlans').document(ds.documentID).updateData({
              'private': false
            }).then((_) => fixed++);
          }
        }
      });

    return fixed;
  }

  Future<int> fixWorkouts() async {
    int fixed = 0;
    await Firestore.instance.collection('workouts').getDocuments()
      .then((qs) async {
        for (DocumentSnapshot ds in qs.documents) {
            DocumentReference workoutRef = Firestore.instance.collection('workouts').document(ds.documentID);
          if (ds.data['author'].isEmpty) {
            await workoutRef.delete();
          }
            fixed++;
        }
      });

    return fixed;
  }



  Future<int> fixUsers() async {
    int fixed = 0;
    await Firestore.instance.collection('users').getDocuments()
      .then((qs) async {
        for (DocumentSnapshot ds in qs.documents) {
          if (!ds.data.containsKey('likes')) {
            await Firestore.instance.collection('users').document(ds.documentID).updateData({
              'likes': <String>[]
            }).then((_) => fixed++);
          }
          if (!ds.data.containsKey('birthday')) {
            await Firestore.instance.collection('users').document(ds.documentID).updateData({
              'birthday': Timestamp.now()
            }).then((_) => fixed++);
          }
        }
      });

    return fixed;
  }