import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String fromUser;
  final String fromGroup;
  String documentID;
  String mediaURL;
  String body;
  Timestamp uploadTime;

  Map<dynamic, dynamic> comments = Map();
  List<String> likes = List();

  Post({
    this.documentID = '', 
    this.fromUser = '', 
    this.fromGroup = '', 
    this.mediaURL = '', 
    this.body = '',
    this.uploadTime,
    this.comments,
    this.likes,
  });

  Map<String, dynamic> toJSON() {
    return  <String, dynamic> {
      'fromUser': fromUser,
      'fromGroup': fromGroup,
      'mediaURL': mediaURL,
      'body': body,
      'comments': comments ?? {},
      'likes': likes ?? [],
      'uploadTime': Timestamp.now(),
    };
  }

  static Post jsonToPost(Map<String, dynamic> data) {
    return Post(
      fromUser: data['fromUser'],
      fromGroup: data['fromGroup'],
      mediaURL: data['mediaURL'],
      body: data['body'],
      comments: data['comments'],
      likes: data['likes'].cast<String>().toList(),
      uploadTime: Timestamp.fromDate(data['uploadTime']),
    );
  }
}