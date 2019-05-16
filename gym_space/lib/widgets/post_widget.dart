import 'package:GymSpace/global.dart';
import 'package:GymSpace/logic/post.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/page/post_comments_page.dart';
import 'package:GymSpace/page/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:GymSpace/page/notification_page.dart';
import 'package:GymSpace/logic/user.dart';
import 'dart:async';
class PostWidget extends StatefulWidget {
  final Post post;

  PostWidget({
    @required this.post,
    Key key}) : super(key: key);

  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  Post get post => widget.post;
  String get currentUserID => DatabaseHelper.currentUserID;

  Future <void> _likePressed() async {
    User currentUser;
    User postUser;
    String userID = DatabaseHelper.currentUserID;
    var datas = await DatabaseHelper.getUserSnapshot(post.fromUser);
    postUser = User.jsonToUser(datas.data);
    if (post.likes.contains(currentUserID)) {
      DatabaseHelper.updatePost(post.documentID, {'likes': FieldValue.arrayRemove([currentUserID])})
        .then((_) {
          setState(() {
            post.likes.remove(currentUserID);
          });
        });
    } else {
      if(post.fromUser != userID){
      DatabaseHelper.getUserSnapshot(userID).then((ds){
        setState(() {
          currentUser = User.jsonToUser(ds.data);
          NotificationPage notify = new NotificationPage();
          notify.sendPostNotification('Post', '${currentUser.firstName} ${currentUser.lastName} has Liked on your post', '${postUser.fcmToken}', 'post', userID, post.documentID); 
          });
        });
      }
      DatabaseHelper.updatePost(post.documentID, {'likes': FieldValue.arrayUnion([currentUserID])})
        .then((_) {
          setState(() {
            // post.likes.add(currentUserID);
          });
        });
    }
  }

  Widget _buildPostHeading() {
    return Container(
      child: FutureBuilder(
        future: DatabaseHelper.getUserSnapshot(post.fromUser),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircleAvatar(
              child: Image.asset(Defaults.userPhoto),
            );
          }
          Map<String, dynamic> user = snapshot.data.data;

          return Container(
            child: ListTile(
              leading: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ProfilePage(forUserID: post.fromUser,)
                )),
                child: CircleAvatar(
                backgroundColor: Colors.transparent,
                backgroundImage: user['photoURL'].isNotEmpty ? CachedNetworkImageProvider(user['photoURL'])
                : AssetImage(Defaults.userPhoto),
                ),
              ),
              title: Container(
                margin: EdgeInsets.only(left: 10),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ProfilePage(forUserID: post.fromUser,)
                  )),
                  child: Text(
                    '${user['firstName']} ${user['lastName']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              subtitle: Container(
                margin: EdgeInsets.only(left: 20),
                child: Text(
                  '${DateFormat('h:mm a MMM d').format(post.uploadTime.toDate())}',
                  style: TextStyle(color: Colors.black38),
                ),
              ),
            ),
          );
        },
      )
    );
  }

  Widget _buildPostContent() {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(post.body)
          ),
          post.mediaURL.isNotEmpty ? 
            FlatButton(
              onPressed: (){},
              child: Container(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      topRight: Radius.circular(20)
                    ),
                  ),
                ),
                child: CachedNetworkImage(
                  useOldImageOnUrlChange: true,
                  imageUrl: post.mediaURL,
                  fit: BoxFit.contain,
                ),    
              ),
            )
          : Container(),
        ],
      ),
    );
  }

  Widget _buildPostFooter() {
    return Container(
      // padding: EdgeInsets.only(bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container( // likes
            child:  FlatButton.icon(
              textColor: post.likes.contains(currentUserID) ? GSColors.lightBlue : GSColors.darkBlue,
              label: Text('${post.likes.length} Likes'),
              icon: Icon(Icons.thumb_up, color: post.likes.contains(DatabaseHelper.currentUserID) ? GSColors.lightBlue : GSColors.darkBlue),
              onPressed: _likePressed,
            ),
          ),
          Container(
            child:  FlatButton.icon(
              textColor: post.comments.isNotEmpty ? GSColors.green : GSColors.darkBlue,
              label: Text('${post.comments.length} Comments'),
              icon: Icon(Icons.comment, color: post.comments.isNotEmpty ? GSColors.green : GSColors.darkBlue),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => PostCommentsPage(postID: post.documentID, postAuthor: post.fromUser))
              )
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)
      ),
      child: Container(
        child: Column(
          children: <Widget>[
            _buildPostHeading(),
            _buildPostContent(),
            Divider(),
            _buildPostFooter(),
          ],
        )
      ),
    );
  }
}