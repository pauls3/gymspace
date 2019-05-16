import 'package:GymSpace/global.dart';
import 'package:GymSpace/logic/post.dart';
import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/page/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:GymSpace/page/notification_page.dart';

class PostCommentsPage extends StatefulWidget {
  final String postID;
  final String postAuthor;

  PostCommentsPage({
    @required this.postID,
    @required this.postAuthor,
    Key key}) : super(key: key);

  _PostCommentsPageState createState() => _PostCommentsPageState();
}

class _PostCommentsPageState extends State<PostCommentsPage> {
  bool _isLoading = false;
  TextEditingController _commentController = TextEditingController();
  String get postID => widget.postID;
  String get postAuthor => widget.postAuthor;
  String get comment => _commentController.text;

  Map<String, dynamic> comments = Map();

  Widget _buildComments() {
    return Container(
      child: StreamBuilder(
        stream: DatabaseHelper.getPostStream(postID),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }

          comments = snapshot.data.data['comments'].cast<String,dynamic>();
          List<Widget> commentWidgets = List();
          List<String> keys = comments.keys.toList();
          keys.sort((String a, String b) => int.parse(a).compareTo(int.parse(b)));
          keys.reversed.forEach((key) => commentWidgets.add(_buildComment(comments[key].cast<String>(), key)));
                    
          return ListView(
            children: commentWidgets,
          );

          // return ListView.builder(
          //   itemCount: comments.length,
          //   itemBuilder: (context, i) {
          //     List<String> loadComment = comments[comments.keys.toList()[i]].cast<String>().toList();
          //     return _buildComment(loadComment, comments.keys.toList()[i]);
          //   },
          // );
        },
      ),
    );
  }

  Widget _buildComment(List<String> loadComment, String time) {
    Duration difference = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(int.parse(time)));
    String commentTime = '';
    if (difference.inDays > 0) {
      commentTime = '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
        commentTime = '${difference.inHours} hrs ago';
    } else if (difference.inMinutes > 0) {
        commentTime = '${difference.inMinutes} mins ago';
    } else {
        commentTime = '${difference.inSeconds} seconds ago';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: FutureBuilder(
        future: DatabaseHelper.getUserSnapshot(loadComment[0]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircleAvatar();
          }

          User user = User.jsonToUser(snapshot.data.data);
          user.documentID = snapshot.data.documentID;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: IconButton(
                      icon: CircleAvatar(
                        backgroundImage: user.photoURL.isNotEmpty ? CachedNetworkImageProvider(user.photoURL)
                          : AssetImage(Defaults.userPhoto),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ProfilePage.fromUser(user)
                      )),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: ShapeDecoration(
                      color: GSColors.cloud,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                      )
                    ),
                    child: InkWell(
                      onLongPress: () => _longPressed(user.documentID, time),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            child: Text(
                              user.firstName + ' ' + user.lastName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              loadComment[1],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Container(
                margin: EdgeInsets.only(left: 40),
                child: Text(
                  commentTime,
                  style: TextStyle(
                    color: Colors.black12
                  ),
                )
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          Flexible(
            child: Container(
              child: TextField(
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                style: TextStyle(color: GSColors.darkBlue, fontSize: 16),
                decoration: InputDecoration.collapsed(
                  hintText: 'Add a comment',
                  hintStyle: TextStyle(color: GSColors.darkCloud)
                ),
              ),
            ),
          ),
          Container(
            child: IconButton(
              icon: Icon(Icons.send, color: GSColors.lightBlue),
              onPressed: _sendPressed,
            )
          )
        ],
      ),
    );
  }

  Future<void> _sendPressed() async {
    if (comment.isEmpty) {
      return;
    }

    String time = Timestamp.now().millisecondsSinceEpoch.toString();
    comments[time] = [DatabaseHelper.currentUserID, comment];
    await DatabaseHelper.updatePost(postID, {'comments': comments}).then((_) {
      print('Commented: $comment');
      FocusScope.of(context).requestFocus(FocusNode());
      _commentController.clear();
    });
    User currentUser;
    User postUser;
    String userID  = DatabaseHelper.currentUserID;
    var data = await DatabaseHelper.getUserSnapshot(postAuthor);
    postUser = User.jsonToUser(data.data);
    if(postAuthor != DatabaseHelper.currentUserID){
      DatabaseHelper.getUserSnapshot(userID).then((ds){
      setState(() {
        currentUser = User.jsonToUser(ds.data);
        NotificationPage notify = new NotificationPage();
        notify.sendPostNotification('Post Comment', '${currentUser.firstName} ${currentUser.lastName} has commented on your post', '${postUser.fcmToken}', 'post', userID, postID); 
        });
      });
    }
  }

  void _longPressed(String userID, String key) {
    if (userID != DatabaseHelper.currentUserID && postAuthor != DatabaseHelper.currentUserID)
      return;
      
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Delete comment?'),
              FlatButton.icon(
                label: Text('Delete'),
                textColor: GSColors.red,
                icon: Icon(Icons.delete, color: GSColors.red,),
                onPressed: () => _deletePressed(key),
              )
            ],
          ),
        );
      }
    );
  }

  void _deletePressed(String key) {
    comments.remove(key);
    DatabaseHelper.updatePost(postID, {'comments': comments}).then((_) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        margin: EdgeInsets.only(top: 10),
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Flexible(
                  child: _buildComments(),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: _buildInput()
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}