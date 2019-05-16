import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meta/meta.dart';
import 'dart:async';
//import 'package:GymSpace/misc/utils.dart';

//Local Notifications Plugin
NotificationDetails get ongoing {
  final andriodChannelSpecifics = AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    'your channel description',
    // styleInformation: Style,
    importance: Importance.Max,
    priority: Priority.High,
    //ongoing: true,
    autoCancel: true,
  );
  final iOSChannelSpecifics = IOSNotificationDetails();
  return NotificationDetails(andriodChannelSpecifics, iOSChannelSpecifics);
}
Future showOngoingNotification (
  FlutterLocalNotificationsPlugin localNotify, {
    @required String title,
    @required String body,
    int id = 0,
  }) => showNotification(localNotify, title: title, body: body, id: id, type: ongoing);

Future showNotification(
  FlutterLocalNotificationsPlugin localNotify, {
    @required String title,
    @required String body, 
    @required NotificationDetails type,
    int id = 0,
  }) => localNotify.show(id, title, body, type);
// Future showIconNotification(
//   BuildContext context,
//   FlutterLocalNotificationsPlugin localNotify, {
//     @required String title,
//     @required String body,
//     @required Image icon,
//     int id = 0,
//   }) async =>
//   localNotify.show(id, title, body, await _icon(context, icon));

// // Future<NotificationDetails> _icon(BuildContext context, Image icon) async {
// //   final iconPath = await saveImage(context, icon);
// //   final androidPlatformChannelSpecifics = AndroidNotificationDetails(
// //     'big text channel id',
// //     'big text channel name',
// //     'big text channel description',
// //     largeIcon: iconPath,
// //     largeIconBitmapSource: BitmapSource.FilePath,
// //   );
// //   return NotificationDetails(androidPlatformChannelSpecifics, null);
// // }
class Notifications{
  String title;
  String body;
  String route;
  String receiver;
  String sender;
  String postID;
  bool read;
  Notifications({
    this.title,
    this.body,
    this.route,
    this.receiver,
    this.sender,
    this.postID,
    this.read
  });
 factory Notifications.fromJSON(Map<dynamic, dynamic> json){
    return Notifications(
     title: json['title'],
     body: json['body'],
     route: json['route'],
     receiver: json['fcmToken'],
     sender: json['sender'],
     postID: json['postID'],
     read: json['read']
    );
  }
}