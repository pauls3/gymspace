import 'dart:async';
import 'package:GymSpace/global.dart';
import 'package:GymSpace/page/notification_page.dart';
import 'package:GymSpace/page/buddy_page.dart';
import 'package:GymSpace/page/message_thread_page.dart';
import 'package:GymSpace/widgets/image_widget.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/logic/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfilePage extends StatefulWidget {
  final String forUserID;
  User user;
  
  ProfilePage({
    @required this.forUserID,
    Key key
    }) : super(key: key);

  ProfilePage.fromUser(this.user, {this.forUserID = ''});

  _ProfilePageState createState() => _ProfilePageState();
   void addBuddy() async {
     print('This is the sender in Profile Page: $forUserID');
    await DatabaseHelper.getUserSnapshot(forUserID).then(
      (ds) => ds.reference.updateData({'buddies': FieldValue.arrayUnion([DatabaseHelper.currentUserID])})
    );
    await DatabaseHelper.getUserSnapshot(DatabaseHelper.currentUserID).then(
      (ds) => ds.reference.updateData({'buddies': FieldValue.arrayUnion([forUserID])})
    );
  }
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isFriend = false;
  bool _isPrivate = true;
  User user;
  Stream<DocumentSnapshot> _streamUser;
  Future<List<String>> _listFutureUser;
  List<String> media = [];
  final localNotify = FlutterLocalNotificationsPlugin();

  @override 
  void initState() {
    super.initState();

    if (widget.user != null) {
      user = widget.user;
      user.buddies = user.buddies.toList();
      user.likes = user.likes.toList();
      user.media = user.media.toList();

      _listFutureUser = DatabaseHelper.getUserMedia(user.documentID);
      _streamUser = DatabaseHelper.getUserStreamSnapshot(user.documentID);
      _isFriend = user.buddies.contains(DatabaseHelper.currentUserID);
      _isPrivate = user.private;

      DatabaseHelper.getUserSnapshot(user.documentID).then((ds) {
      setState(() {
        user = User.jsonToUser(ds.data);
        user.documentID = ds.documentID;
          if (user.buddies.contains(DatabaseHelper.currentUserID)) {
            _isFriend = true;
          }
        });
      });
    } else {
      _loadUser();
    }

    final settingsAndriod = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settingsIOS = IOSInitializationSettings(
    onDidReceiveLocalNotification: (id, title, body, payload) =>
        onSelectNotification(payload));
    localNotify.initialize(InitializationSettings(settingsAndriod, settingsIOS),
      onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async  {
    Navigator.pop(context);
    print("==============OnSelect WAS CALLED===========");
    await Navigator.push(context, new MaterialPageRoute(builder: (context) => NotificationPage()));
  } 

  Future<void> _loadUser() async {
    DatabaseHelper.getUserSnapshot(widget.forUserID).then((ds) {
      setState(() {
        user = User.jsonToUser(ds.data);
        user.documentID = widget.forUserID;
        _isFriend = user.buddies.contains(DatabaseHelper.currentUserID);
      });
    });
  }

 
  void _addPressed() async {
    if (user.buddies.contains(DatabaseHelper.currentUserID)) {
      return;
    }
    // Send Notification for the Buddy Request
    User currentUser;
    String userID = DatabaseHelper.currentUserID;
    DatabaseHelper.getUserSnapshot(userID).then((ds){
      setState(() {
        currentUser = User.jsonToUser(ds.data);
        NotificationPage notify = new NotificationPage();
        notify.sendNotifications('Buddy Request', '${currentUser.firstName} ${currentUser.lastName} has sent a Buddy Request', '${user.fcmToken}','buddy', userID);
      });
    });
    // setState(() {
    //   user.buddies.toList().add(DatabaseHelper.currentUserID);
    //   _isFriend = true;
    // });
  }

  void _deletePressed() async {
   showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        title: Text('Remove Friend?'),
        contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Container(
          child: Text(
            'Do you want unfriend this person?',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
            textColor: GSColors.green,
          ),
          FlatButton(
            onPressed: () => _deleteBuddy(user.documentID),
            child: Text('Yes'),
            textColor: GSColors.green,
          ),
        ],
      )
    ); 
  }

  Future<void> _deleteBuddy(String buddyID) async {
    await Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
      {'buddies': FieldValue.arrayRemove([buddyID])}
    ).then((_) => print('Successfully deleted buddy from current user'));

    await Firestore.instance.collection('users').document(buddyID).updateData(
      {'buddies': FieldValue.arrayRemove([DatabaseHelper.currentUserID])}
    ).then((_) {
      print('Successfully deleted current user from buddy.');
      setState(() {
        _isFriend = false;
        Navigator.pop(context);
      });
    });
  }

  void _openMessages() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => MessageThreadPage(
        peerId: user.documentID,
        peerAvatar: user.photoURL,
        peerFirstName: user.firstName,
        peerLastName: user.lastName,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: user == null ? 
      Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()),
      ) 
      : Scaffold(
        // drawer: AppDrawer(startPage: 0,),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(450),
          child: _buildAppBar(),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      child: Stack(
        children: <Widget>[
          Container(
            height: 400,
            child: AppBar(
              // elevation: .5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: _buildProfileHeading(),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileHeading() {
    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: FractionalOffset.topCenter,
          end: FractionalOffset.bottomCenter,
          stops: [.32, .35,],
          colors: [GSColors.darkBlue, Colors.white],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        )
      ),
      child: Column(
        children: <Widget>[
          _buildAvatarStack(),
          Divider(color: Colors.transparent,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text( // name
                '${user.firstName} ${user.lastName}',
                style: TextStyle(
                  // color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Container( // points icon
                margin: EdgeInsets.only(left: 10),
                child: Icon(
                  Icons.stars,
                  size: 14,
                  color: GSColors.green,
                ),
              ),
              Container( // points
                margin: EdgeInsets.only(left: 4),
                child: Text(
                  user.points.toString(),
                  style: TextStyle(
                    color: GSColors.green,
                    fontSize: 14
                  ),
                )
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 3),
            child: Text(
              user.liftingType,
              style: TextStyle(
                // color: Colors.white,
                fontWeight: FontWeight.w300
              ),
            ),
          ),
          user.bio != null ? Container( // actual bio
            // color: Colors.red,
            margin: EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            child: Text(
              user.bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GSColors.darkBlue,
                letterSpacing: 1.2
              ),
            ),
          ) 
          : Container(),
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                user == null || user.documentID == DatabaseHelper.currentUserID || widget.forUserID == DatabaseHelper.currentUserID ? 
                Container() : 
                FlatButton.icon(
                  icon: Icon(Icons.mail_outline),
                  label: Text('Message'),
                  textColor: GSColors.darkBlue,
                  color: GSColors.cloud,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _openMessages(),
                ),
                user == null || user.documentID == DatabaseHelper.currentUserID || widget.forUserID == DatabaseHelper.currentUserID ? 
                Container() : 
                FlatButton.icon(
                  icon: Icon(_isFriend ? Icons.check : Icons.add),
                  label: Text(_isFriend ? 'Buddies' : 'Add Buddy'),
                  textColor: GSColors.darkBlue,
                  color: GSColors.lightBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _isFriend ? _deletePressed() : _addPressed(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _likePressed() {
    if (user.likes.contains(DatabaseHelper.currentUserID)) {
      DatabaseHelper.updateUser(user.documentID, {'likes': FieldValue.arrayRemove([DatabaseHelper.currentUserID])})
      .then((_) {
        setState(() {
          Fluttertoast.showToast(msg: 'Unliked!');
        });
      });
      return;
    }

    DatabaseHelper.updateUser(user.documentID, {'likes': FieldValue.arrayUnion([DatabaseHelper.currentUserID])})
      .then((_) {
        setState(() {
          Fluttertoast.showToast(msg: 'Liked!');
        });
      });
  }

  Widget _buildAvatarStack() {
    return Container(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            left: 60,
            child: InkWell(
              onTap: _likePressed,
              child: Row( // likes
                children: <Widget> [
                  Icon(Icons.thumb_up, color: GSColors.lightBlue,),
                  StreamBuilder(
                    stream: DatabaseHelper.getUserStreamSnapshot(DatabaseHelper.currentUserID),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Text(' ${user.likes.length}', style: TextStyle(color: GSColors.lightBlue),);
                      }

                      return Text(' ${user.likes.length}', style: TextStyle(color: GSColors.lightBlue),);
                  },
                ),
              ],
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.only(top: 10),
            alignment: Alignment.center,
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute<void> (
                builder: (BuildContext context) {
                  return ImageWidget(user.photoURL, context, false);
                }),
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundImage: user.photoURL.isNotEmpty ? CachedNetworkImageProvider(user.photoURL)
                : AssetImage(Defaults.userPhoto),
              ),
            ),
            decoration: ShapeDecoration(
              shadows: [BoxShadow(blurRadius: 4, spreadRadius: 2)],
              shape: CircleBorder(
                side: BorderSide(
                  color: Colors.white,
                  width: 1,
                )
              ),
            ),
          ),
          
          Positioned(
            right: 40,
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => BuddyPage.fromUser(user, true))
              ),
              child: Row( // likes
                children: <Widget> [
                  Icon(Icons.group, color: GSColors.purple,),
                  StreamBuilder(
                    stream: DatabaseHelper.getUserStreamSnapshot(DatabaseHelper.currentUserID),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Text(' ${user.buddies.length} buddies', style: TextStyle(color: GSColors.purple),);
                      }

                      return Text(' ${user.buddies.length} buddies', style: TextStyle(color: GSColors.purple),);
                    },
                  )
                ],
              ),
            )
          ),
        ]
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      child: ListView(
        children: <Widget>[
          _isPrivate && !_isFriend && user.documentID != DatabaseHelper.currentUserID ? _buildPrivate()
            : _buildPublic(),
        ],
      ),
    );
  }

  Widget _buildPrivate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget> [
        Container(
          margin: EdgeInsets.only(top: 50),
          alignment: Alignment.center,
          child: Icon(
            Icons.lock_outline,
            size: 80,)
        ),
        Container(
          alignment: Alignment.center,
          child: Text(
            "This Account is Private",
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ),
        Container(
          alignment: Alignment.center,
          child: Text(
            "Try becoming buddies to see their activity!",
          )
        ),
      ],
    );
  }

  Widget _buildPublic() {
    return Column(
      children: <Widget>[
        _buildWeightInfo(),
        _buildMedia(),
      ],
    );
  }

  // Widget _buildBio() {
  //   return Container(
  //     margin: EdgeInsets.only(top: 30),
  //     child: Column(
  //       children: <Widget>[
  //         Container( // label
  //           child: Row(
  //             children: <Widget>[
  //               Expanded(
  //                 flex: 2,
  //                 child: Container(
  //                   alignment: Alignment.center,
  //                   height: 40,
  //                   decoration: ShapeDecoration(
  //                     color: GSColors.darkBlue,
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.only(
  //                         bottomRight: Radius.circular(20),
  //                         topRight: Radius.circular(20),
  //                       )
  //                     )
  //                   ),
  //                   child: Text(
  //                     'Bio',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 14,
  //                       letterSpacing: 1.2
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               Expanded(
  //                 flex: 1,
  //                 child: Container(),
  //               )
  //             ],
  //           ),
  //         ),
  //         Container( // actual bio
  //           // color: Colors.red,
  //           margin: EdgeInsets.symmetric(vertical: 10, horizontal: 40),
  //           alignment: Alignment.center,
  //           child: Text(
  //             user.bio,
  //             textAlign: TextAlign.center,
  //             style: TextStyle(
  //               color: GSColors.darkBlue,
  //               letterSpacing: 1.2
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildWeightInfo() {
  return Container(
        margin: EdgeInsets.only(top: 30, left: 10, right: 10),
        decoration: ShapeDecoration(
          color: GSColors.darkBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              topLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
              topRight: Radius.circular(20),
            )
          )
        ),
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Stack(
          children: <Widget>[ 
            _buildStartingWeight(),
            _buildCurrentWeight(),
          ],
        ),
    );
  }

  Widget _buildCurrentWeight() {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Expanded(
          flex: 6,
          child: Container(
            margin: EdgeInsets.only(left: 20),
            padding: EdgeInsets.only(top: 30, bottom: 5),
            alignment: Alignment.centerLeft,
            child: Text(
              "Current Weight",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              )),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.only(top: 30, bottom: 5),
            alignment: Alignment.center,
            child: StreamBuilder(
              stream: _streamUser,
              builder: (context, snapshot) =>
                Text(
                  snapshot.hasData ? snapshot.data['currentWeight'].toString() + ' lbs' : '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14
                  ),
                )
              ),
            ),
          ),
          Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.only(top: 30, bottom: 5),
            alignment: Alignment.centerLeft,
            child: StreamBuilder(
              stream: _streamUser,
              builder: (context, snapshot) {
                double weightLost = snapshot.hasData ? (snapshot.data['startingWeight'] - snapshot.data['currentWeight']) : 0;
                
                if(weightLost > 0)
                  return Row(
                    children: <Widget>[
                      Icon(FontAwesomeIcons.caretDown, color: Colors.red, size: 16),
                      Text(
                        weightLost.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      )
                    ],
                  );
                else if (weightLost < 0) {
                  return Row(
                    children: <Widget>[
                      Icon(FontAwesomeIcons.caretUp, color: GSColors.green, size: 16),
                      Text(
                          weightLost.toStringAsFixed(1),
                          style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      )
                    ],
                  );
                } else 
                  return Container();
              }
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartingWeight() {
      return Row(
      children: <Widget>[
        Expanded(
          flex: 6,
          child: Container(
            margin: EdgeInsets.only(left: 20),
            padding: EdgeInsets.symmetric(vertical: 5),
            alignment: Alignment.centerLeft,
            child: Text(
              "Starting Weight",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              )),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            margin: EdgeInsets.only(left: 20),
            child: StreamBuilder(
              stream: _streamUser,
              builder: (context, snapshot) =>
              Text(
                snapshot.hasData ? snapshot.data['startingWeight'].toString() + " lbs" : "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14
                ),
              )
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(),
        ),
      ],
    );
  }

  Widget _buildMedia() {
    return Container( // 
      margin: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: <Widget>[
          Container(  // label
            alignment: Alignment.center,
            child: Column(
              children: <Widget>[
                Text(
                  'Media',
                  style: TextStyle(
                    color: GSColors.darkBlue,
                    fontSize: 20,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  )
                ),
                Text(
                  user.media.length.toString() + ' shots',
                  style: TextStyle(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          Container( // photo gallery
            margin: EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 10),
            child: FutureBuilder(
              future: _listFutureUser,
              builder: (context, snapshot) {
                if(!snapshot.hasData)
                  return Container();

                media = snapshot.data;
                return GridView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  primary: false,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemCount: media.length,
                  itemBuilder: (BuildContext context, int i) {

                  return _buildMediaItem(media[i]);
                  }
                );
              }
            )
          ),
        ],
      ),
    );
  }

   Widget _buildMediaItem(String media) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute<void> (
          builder: (BuildContext context) {
            return ImageWidget(media, context, false);
          },
        )
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Image.network(media).image,
            fit: BoxFit.cover
          ),
          border: Border.all(
            color: GSColors.darkBlue,
            width: 0.5,
          )
        ),
      ),
    );
  }
}