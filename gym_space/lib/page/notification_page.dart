import 'package:GymSpace/page/post_comments_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:GymSpace/widgets/app_drawer.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:GymSpace/logic/notification.dart';
import 'package:GymSpace/notification_api.dart';
import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/global.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:GymSpace/page/profile_page.dart';
import 'package:GymSpace/page/messages_page.dart';
import 'package:flutter/widgets.dart';

class NotificationPage extends StatefulWidget {
  @override 
  _NotificationState createState() => new _NotificationState();
  void sendNotifications(String title, String body, String fcmToken, String route, String sender) async {
    final response = await Messaging.sendTo(
      title: title,
      body: body,
      fcmToken: fcmToken,
      route: route,
      sender: sender,
    );
    print('title: $title');
    print('body: $body');
    print('fcmToken: $fcmToken');
    print('route: $route');
    print('sender: $sender');
    if(response.statusCode != 200){}
  }
  void sendPostNotification(String title, String body, String fcmToken, String route, String sender, String postID) async{
    final response = await Messaging.sendTo(
      title: title,
      body: body,
      fcmToken: fcmToken,
      route: route,
      sender: sender,
      postID: postID
    );
    print('title: $title');
    print('body: $body');
    print('fcmToken: $fcmToken');
    print('route: $route');
    print('sender: $sender');
    print('postID: $postID');
    if(response.statusCode != 200){}
  }
  void sendTokenToServer(String fcmToken){
    // Update user's fcmToken just in case
    String userID = DatabaseHelper.currentUserID;
    Firestore.instance.collection('users').document(userID).updateData({'fcmToken': fcmToken});
  } 
}

class _NotificationState extends State<NotificationPage> {
  final FirebaseMessaging _messaging = new FirebaseMessaging();
  final localNotify = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _messaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        final notification = message['notification'];
        final data = message ['data'];
        _sendNotificationToDB(notification['title'], notification['body'], data['route'],data['fcmToken'],data['sender'], data['postID'], false);
        showOngoingNotification(localNotify, id: 0, title: notification['title'], body: notification['body']);
      },
      onLaunch:  (Map<String, dynamic> message) async {
        print("onLaunch: $message");
         final notification = message['data'];
        //_sendNotificationToDB(notification['title'], notification['body'], notification['route'], notification['fcmToken'],notification['sender']);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        final notification = message['data'];
        //showOngoingNotification(localNotify, id: 0, title: notification['title'], body: notification['body']);
        _sendNotificationToDB(notification['title'], notification['body'], notification['route'], notification['fcmToken'],notification['sender'], notification['postID'], false);
        handleResumeRouting('notification');
      }
    );
    _messaging.onTokenRefresh.listen(sendTokenToServer);
    _messaging.getToken();
    _messaging.subscribeToTopic('all');
    final settingsAndriod = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settingsIOS = IOSInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) =>
        onSelectNotification(payload));
    localNotify.initialize(InitializationSettings(settingsAndriod, settingsIOS),
      onSelectNotification: onSelectNotification);
  }
  void sendTokenToServer(String fcmToken){
    print(fcmToken);
    // Update user's fcmToken just in case
    String userID = DatabaseHelper.currentUserID;
    Firestore.instance.collection('users').document(userID).updateData({'fcmToken': fcmToken});
  } 

  Future<void> handleRouting(dynamic notify) async{
    DocumentSnapshot itemCount = await Firestore.instance.collection('users').document(notify.sender).get();
    User userInfo = User.jsonToUser(itemCount.data);
    //Navigator.pop(context);
    print(notify.route);
    switch (notify.route){
      case 'buddy':
        Navigator.of(context).push(
          new MaterialPageRoute(builder: (BuildContext context) => ProfilePage.fromUser(userInfo))
        );
        break;
      case 'message':
        Navigator.of(context).push(
          new MaterialPageRoute(builder: (BuildContext context) => MessagesPage())
        );
        break;
      case 'post':
        print('this is postID: ${notify.postID}');
        Navigator.of(context).push(new MaterialPageRoute(
          builder: (BuildContext context) => PostCommentsPage(postID: notify.postID, postAuthor: DatabaseHelper.currentUserID)
        ));
        break;
      case 'group':
        Navigator.of(context).push(
          new MaterialPageRoute(builder: (BuildContext context) => ProfilePage.fromUser(userInfo))
        );
        break;
    }
  }
  void handleResumeRouting(String notify){
    Navigator.pop(context);
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (BuildContext context) => NotificationPage()));
  }
  
  Future<void> _sendNotificationToDB(String title, String body, String route, String fcmToken, String sender, String postID, bool read) async{
    Map<String, dynamic> notification =
     {
      'title': title,
      'body': body,
      'route': route,
      'fcmToken': fcmToken,
      'sender': sender,
      'postID': postID,
      'read': read
    };
    
    Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
      {'notifications': FieldValue.arrayUnion([notification])}
    );
  }
  Future<void> _deleteNotificationOnDB(String sender, String route, String receiver) async  {
    // Get specific notification from DB
    DocumentSnapshot itemCount = await Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).get();
    User userInfo = User.jsonToUser(itemCount.data);
    Map<dynamic, dynamic> notification;
    List<Map<dynamic,dynamic>> jsonData = userInfo.notifications;
    // fully check to find the specific array in the Notifications
    for(final name in jsonData){
      if(name.containsValue(sender))  // narrow down the sender's value first
        if(name.containsValue(route)) // then narrow down to route's value
          if(name.containsValue(receiver))  // then last check the receiver's value 
             notification = name;
    }
    // Delete specific notification from DB
    Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
      {'notifications': FieldValue.arrayRemove([notification])}
    );
    print("Deleted Object");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(startPage: 5),
      backgroundColor: GSColors.darkBlue,
      body: _buildBody(context)
      );
  }

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: PageHeader(
        title: "Notifications",
        backgroundColor: Colors.white,
        showDrawer: true,
        titleColor: GSColors.darkBlue,
      ),
    );
  } 
  Widget _buildBody(BuildContext context){
    return StreamBuilder<DocumentSnapshot>(
      stream: Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).snapshots(),
      builder: (context, snapshot){
        if(!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data['notifications'].cast<Map<dynamic,dynamic>>());
      }
    );
  }
  Widget _buildList(BuildContext context, List<Map<dynamic, dynamic>> snapshot){
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
      shrinkWrap: true ,
    );
  }
  Widget _buildListItem(BuildContext context, Map<dynamic, dynamic> data){
    final notify = Notifications.fromJSON(data);
    Future<DocumentSnapshot> _otherUser =  DatabaseHelper.getUserSnapshot(notify.sender);
    ProfilePage otherUsersZ = ProfilePage(forUserID: notify.sender);
    if(notify.route == 'buddy'){
      return Padding(
        key: ValueKey(notify.title),
        padding: const EdgeInsets.symmetric( horizontal: 0, vertical: 0),
        child: Card(
          elevation: 8.0 ,
          color: GSColors.blue,
            child: GestureDetector(
            onTap: () {
              handleRouting(notify);
              if(notify.read == false){
              _deleteNotificationOnDB(notify.sender, notify.route, notify.receiver);
              }
              _sendNotificationToDB(notify.title, notify.body, notify.route, notify.receiver, notify.sender, notify.postID, true);
            },
            child: Card(
              elevation: 8,
                child: Container(
                padding: EdgeInsets.only(left:10.0, top: 10, bottom: 10,),
                decoration: BoxDecoration(
                  color:(notify.read != true) ? GSColors.darkCloud : GSColors.cloud,
                  border: Border.all(color: GSColors.darkCloud),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                  FutureBuilder(
                        future: _otherUser,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container();
                          }

                          return CircleAvatar(radius: 30,
                            backgroundImage: snapshot.data['photoURL'].isNotEmpty ? CachedNetworkImageProvider(snapshot.data['photoURL']) : AssetImage(Defaults.userPhoto),
                          );
                        }
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FittedBox(
                          child: Text(notify.title, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5),
                          ),
                          fit: BoxFit.fill
                          ),
                          FittedBox(
                            child: Text(notify.body, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.0)),
                            fit: BoxFit.fill
                          )
                        ],
                      ),
                    ),
                    RawMaterialButton(
                      constraints: BoxConstraints.tight(Size(35,35)),
                      onPressed: () { otherUsersZ.addBuddy(); _deleteNotificationOnDB(notify.sender, notify.route, notify.receiver);},
                      child: Icon (
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 20.0
                      ),
                      shape: CircleBorder(),
                      elevation: 10.0,
                      fillColor: GSColors.darkBlue,
                    ),
                    RawMaterialButton(
                      constraints: BoxConstraints.tight(Size(35,35)),
                      onPressed: () => _deleteNotificationOnDB(notify.sender, notify.route, notify.receiver),
                      child: Icon (
                        Icons.cancel,
                        color: Colors.redAccent,
                        size: 20.0
                      ),
                      shape: CircleBorder(),
                      elevation: 10.0,
                      fillColor: GSColors.darkBlue,
                    ),
                    RawMaterialButton(
                      constraints: BoxConstraints.tight(Size(35,35)),
                      onPressed: () => _deleteNotificationOnDB(notify.sender, notify.route, notify.receiver),
                      child: new Icon(
                        Icons.delete,
                        color: GSColors.darkCloud,
                        size: 20.0,
                      ),
                      shape: new CircleBorder(),
                      elevation: 10.0,
                      fillColor: GSColors.darkBlue,
                    )
                  ],
                )
              ),
            ),
          ),
        ), 
      );
    }
    else {
       return Padding(
        key: ValueKey(notify.title),
        padding: const EdgeInsets.symmetric( horizontal: 0, vertical: 0),
        child: Card(
          elevation: 8.0 ,
          color: GSColors.blue,
            child: GestureDetector(
            onTap: () {
              handleRouting(notify);
              if(notify.read == false){
              _deleteNotificationOnDB(notify.sender, notify.route, notify.receiver);
              }
              _sendNotificationToDB(notify.title, notify.body, notify.route, notify.receiver, notify.sender, notify.postID, true);
            },
            child: Card(
              elevation: 8,
                child: Container(
                padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
                decoration: BoxDecoration(
                  color:(notify.read != true) ? GSColors.darkCloud : GSColors.cloud,
                  border: Border.all(color: GSColors.darkCloud),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                  FutureBuilder(
                        future: _otherUser,
                        builder: (context, snapshot){
                          return CircleAvatar(radius: 30,
                            backgroundImage: snapshot.hasData ? CachedNetworkImageProvider(snapshot.data['photoURL']) : AssetImage(Defaults.userPhoto),
                          );
                        }
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FittedBox(
                          child: Text(notify.title, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5),
                          ),
                          fit: BoxFit.scaleDown
                          ),
                          FittedBox(
                            child: Text(notify.body, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.0)),
                            fit: BoxFit.scaleDown
                          )
                        ],
                      ),
                    ),
                    RawMaterialButton(
                      onPressed: () => _deleteNotificationOnDB(notify.sender, notify.route, notify.receiver),
                      child: new Icon(
                        Icons.delete,
                        color: GSColors.darkCloud,
                        size: 20.0,
                      ),
                      shape: new CircleBorder(),
                      elevation: 10.0,
                      fillColor: GSColors.darkBlue,
                    )
                  ],
                )
              ),
            ),
          ),
        ), 
      );
    }
  }
  

  // Local Notifications Plugin Functions
  Future onSelectNotification(String payload) async  {
    print("==============OnSelect WAS CALLED===========");
    await Navigator.push(context, new MaterialPageRoute(builder: (context) => NotificationPage()));
  }
}
