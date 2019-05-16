import 'dart:async';

import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/page/profile_page.dart';
import 'package:GymSpace/page/search_page.dart';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:flutter/widgets.dart';
import 'package:GymSpace/global.dart';
import 'package:GymSpace/page/notification_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BuddyPage extends StatefulWidget {
  User user;
  bool fromUser;

  BuddyPage({Key key}) : super(key: key);
  BuddyPage.fromUser(this.user, this.fromUser, {Key key}) : super(key: key);
  _BuddyPageState createState() => _BuddyPageState();
}

class _BuddyPageState extends State<BuddyPage> {
  List<String> buddies =  [];
  User user;
  bool _fromUser = false;
  final localNotify = FlutterLocalNotificationsPlugin();
  //Algolia get algolia => DatabaseConnections.algolia;

  @override
  void initState() {
    super.initState();

    if(widget.fromUser == true) {
      print("a");
      user = widget.user;
      user.buddies = user.buddies.toList();
      _fromUser = true;

    // } else if(widget.fromUser == true && widget.fromUser == null) { 
    //   print("b");
    //   _fromUser = true; 

    } else {
      print("c");
      user = widget.user;
      user.buddies = user.buddies.toList();
      _fromUser = false;
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

  Future<void> searchPressed() async {
    List<User> allUsers = List();
    QuerySnapshot userSnapshots = await Firestore.instance.collection('users').getDocuments();
    userSnapshots.documents.forEach((ds) {
      User user = User.jsonToUser(ds.data);
      user.documentID = ds.documentID;
      allUsers.add(user);
    });

    User _currentUser;
    await DatabaseHelper.getUserSnapshot(DatabaseHelper.currentUserID).then(
      (ds) => _currentUser = User.jsonToUser(ds.data)
    );

    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return SearchPage(searchType: SearchType.user, 
          currentUser: _currentUser, users: allUsers);
      } 
    ));
  }

  void _deletePressed(String buddyID) async {
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
            'Are you sure you want unfriend this person?',
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
            onPressed: () => _deleteBuddy(buddyID),
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
        Navigator.pop(context);
      });
    });
  }

  Widget build(BuildContext context) {
    return SafeArea(
    // case where user calls buddies themselves
    child: _fromUser == false ? Scaffold(
      // drawer: AppDrawer(startPage: 5),
      backgroundColor: GSColors.darkBlue,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: GSColors.purple,
        foregroundColor: Colors.white,
        child: Icon(Icons.search),
        onPressed: () => searchPressed(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ) 
      : Scaffold(
        backgroundColor: GSColors.darkBlue,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: GSColors.purple,
          foregroundColor: Colors.white,
          child: Icon(Icons.search),
          onPressed: () => searchPressed(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      )
    );
  }

  Widget _buildAppBar() {
    if(_fromUser == true) {
      print("First");
      return PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: PageHeader(
          title: "${user.firstName}'s Buddies", 
          backgroundColor: Colors.white,
          titleColor: GSColors.darkBlue,
          //showSearch: true,
          //searchFunction: searchPressed,
        )
      );  
    // } else if(_fromUser == false && user == null) {
    //   print("Second");
    //   return PreferredSize(
    //     preferredSize: Size.fromHeight(100),
    //     child: PageHeader(
    //       title: "Your Buddies", 
    //       backgroundColor: Colors.white,
    //       showDrawer: true,
    //       titleColor: GSColors.darkBlue,
    //       showSearch: true,
    //       searchFunction: searchPressed,
    //     )
    //   );  
    } else {
      print("Third");
      return PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: PageHeader(
          title: "Your Buddies", 
          backgroundColor: Colors.white,
          //showDrawer: true,
          titleColor: GSColors.darkBlue,
          //showSearch: true,
          //searchFunction: searchPressed,
        )
      );  
    }
  }

  Widget _buildBody() {
    return Stack(
      children: <Widget> [
        // Background
        Container(
          margin: EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 20),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: Container(
            margin: EdgeInsets.all(15),
            child: _buildBuddyList(),
          )
        ),
      ]
    );
  }

  Widget _buildBuddyList() {
    if(_fromUser == true) {
      return StreamBuilder(
        stream: DatabaseHelper.getUserStreamSnapshot(user.documentID),
        builder: (context, snapshot) {
          if(!snapshot.hasData) 
            return Container();
                
          buddies = snapshot.data.data['buddies'].cast<String>();
          return ListView.builder(
            itemCount: buddies.length,
            itemBuilder: (BuildContext context, int i) {            
              return StreamBuilder(
                stream: DatabaseHelper.getUserStreamSnapshot(buddies[i]),
                builder: (context, snapshot) {
                  if(!snapshot.hasData)
                    return Container();

                  user = User.jsonToUser(snapshot.data.data);
                  user.documentID = snapshot.data.documentID;
                  int mutualFriends = 0;
                  for(String buddyID in user.buddies) {
                    if (snapshot.data['buddies'].contains(buddyID)) 
                      mutualFriends++;
                  }
                  return _buildBuddy(user, mutualFriends);
                },
              );
            }, 
          );
        },
      );
    } else {
        return StreamBuilder(
          stream: DatabaseHelper.getUserStreamSnapshot(DatabaseHelper.currentUserID),
          builder: (context, snapshot) {
            if(!snapshot.hasData) 
              return Container(); 
            
            buddies = snapshot.data.data['buddies'].cast<String>();
            return ListView.builder(
              itemCount: buddies.length,
              itemBuilder: (BuildContext context, int i) {           
                return StreamBuilder(
                  stream: DatabaseHelper.getUserStreamSnapshot(buddies[i]),
                  builder: (context, snapshot) {
                    if(!snapshot.hasData)
                      return Container();

                    user = User.jsonToUser(snapshot.data.data);
                    user.documentID = snapshot.data.documentID;
                    int mutualFriends = 0;
                    for(String buddyID in user.buddies) {
                      if (snapshot.data['buddies'].contains(buddyID)) 
                        mutualFriends++;
                    }
                    return _buildBuddy(user, mutualFriends);
                  },
                );
              }, 
            );
          },
        );
    }
  }

  // Buddy container
  Widget _buildBuddy(User user, int mutualFriends) {
    bool _isFriend;

    if(_fromUser == false) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
          onTap: () => _buildBuddyProfile(user),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                decoration: ShapeDecoration(
                  color: GSColors.darkBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)
                  )
                ),
                child: 
                  Center(
                    child: Column(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 12, left: 30),
                          child: Text(
                            '${user.firstName} ${user.lastName}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24
                            ),
                          ),
                        ),
                        Divider(height: 5),
                        Container(
                          margin: EdgeInsets.only(bottom: 12, left: 30),
                          child: Text(
                            '${user.liftingType}',
                            style: TextStyle(
                              color: Colors.white70
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: ShapeDecoration(
                    shadows: [BoxShadow(blurRadius: 2)],
                    shape: CircleBorder(
                      side: BorderSide(color: Colors.black, width: .25)
                    )
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: user.photoURL.isNotEmpty ? CachedNetworkImageProvider(user.photoURL)
                    : AssetImage(Defaults.userPhoto),
                  ),
                )
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: EdgeInsets.only(right: 4),
                  child:IconButton(
                    onPressed: () => _deletePressed(user.documentID),
                    color: Colors.red,
                    iconSize: 30,
                    icon: Icon(Icons.cancel),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
          onTap: () => _buildBuddyProfile(user),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                decoration: ShapeDecoration(
                  color: GSColors.darkBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)
                  )
                ),
                child: 
                  Center(
                    child: Column(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: 12, left: 30),
                          child: Text(
                            '${user.firstName} ${user.lastName}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24
                            ),
                          ),
                        ),
                        Divider(height: 5),
                        Container(
                          margin: EdgeInsets.only(bottom: 12, left: 30),
                          child: Text(
                            '${user.liftingType}',
                            style: TextStyle(
                              color: Colors.white70
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: ShapeDecoration(
                    shadows: [BoxShadow(blurRadius: 2)],
                    shape: CircleBorder(
                      side: BorderSide(color: Colors.black, width: .25)
                    )
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: user.photoURL.isNotEmpty ? CachedNetworkImageProvider(user.photoURL)
                    : AssetImage(Defaults.userPhoto),
                  ),
                )
              ),
              Positioned(
                right: 8, top: 25,
                child: Container(
                  margin: EdgeInsets.only(right: 4),
                  child: Column( // likes
                  children: <Widget> [
                    Icon(Icons.group, color: GSColors.purple, size: 18,),

                    mutualFriends > 1 
                      ? Text(
                      mutualFriends.toString() + ' mutuals', 
                      style: TextStyle(
                      color: GSColors.purple,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    )) 
                    : mutualFriends == 0 
                      ? Text(
                      '${user.buddies.length} buddies', 
                      style: TextStyle(
                      color: GSColors.purple,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    )) 
                    : Text(
                        mutualFriends.toString() + ' mutual', 
                        style: TextStyle(
                        color: GSColors.purple,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      )),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _buildBuddyProfile(User user) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ProfilePage.fromUser(user)
    ));
  }
}