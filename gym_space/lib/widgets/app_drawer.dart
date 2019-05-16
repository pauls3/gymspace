import 'dart:async';
import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/page/nutrition_page.dart';
import 'package:GymSpace/page/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/page/workout_plan_home_page.dart';
import 'package:GymSpace/page/me_page.dart';
import 'package:GymSpace/page/buddy_page.dart';
import 'package:GymSpace/global.dart';
import 'package:GymSpace/logic/auth.dart';
import 'package:GymSpace/page/login_page.dart';
import 'package:GymSpace/page/messages_page.dart';
import 'package:GymSpace/page/groups_page.dart';
import 'package:GymSpace/page/newsfeed_page.dart';
import 'package:GymSpace/page/settings_page.dart';
import 'package:GymSpace/page/notification_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:GymSpace/page/leaderboard_page.dart';
class AppDrawer extends StatefulWidget {
  final Widget child;
  final int startPage;

  AppDrawer({Key key, this.child, this.startPage = 2}) : super(key: key);

  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  int _currentPage = 2; // 0-7 drawer items are assigned pages when they are built
  Future<DocumentSnapshot> _futureUser =  DatabaseHelper.getUserSnapshot( DatabaseHelper.currentUserID);
  
  final localNotify = FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    _currentPage = widget.startPage;
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
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 20),
                child: FutureBuilder(
                  future: _futureUser,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(Defaults.userPhoto),
                      );
                    }

                    User user = User.jsonToUser(snapshot.data.data);
                    user.documentID = snapshot.data.documentID;

                    return Container(
                      decoration: ShapeDecoration(
                        shadows: [BoxShadow(blurRadius: 4,)],
                        shape: CircleBorder(
                          side: BorderSide(color: Colors.white, width: .5)
                        ),
                      ),
                      child: FlatButton(
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 70,
                          backgroundImage: user.photoURL.isNotEmpty ? CachedNetworkImageProvider(user.photoURL)
                            : AssetImage(Defaults.userPhoto),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => MePage.thisUser(user)
                        )),
                      )
                    );
                  },
                ),
              ),
              Center(
                child: FutureBuilder(
                  future: _futureUser,
                  builder: (contex, snapshot) {
                    String name = snapshot.hasData ? snapshot.data['firstName'] + ' ' + snapshot.data['lastName'] : "";
                    
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    );
                  }
                )
              ),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    _buildDrawerItem("Newsfeed", FontAwesomeIcons.newspaper, 0),
                    _buildDrawerItem("Workout Plans", FontAwesomeIcons.dumbbell, 1),
                    _buildDrawerItem("Profile", FontAwesomeIcons.userCircle, 2),
                    _buildDrawerItem("Nutrition", FontAwesomeIcons.utensils, 3),
                    _buildDrawerItem("Groups", FontAwesomeIcons.users, 4),
                    //_buildDrawerItem("Buddies", FontAwesomeIcons.userFriends, 5),
                    _buildDrawerItem("Notifications", FontAwesomeIcons.bell, 5),
                    _buildDrawerItem("Messages", FontAwesomeIcons.comments, 6),
                    _buildDrawerItem("Leader Board", FontAwesomeIcons.star, 7)
                    //_buildDrawerItem("Settings", FontAwesomeIcons.slidersH, 8),
                  ],
                ),
              ),
              Container(
                child: ListTile(
                  onTap: _loggedOut,
                  title: Text(
                    "Logout", style:TextStyle(color: Colors.red),
                  ),
                  leading: Icon(FontAwesomeIcons.signOutAlt, color: Colors.red,),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, int page) {
    // current page is given a blue background and indented
    if (_currentPage == page) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 40),
        decoration: ShapeDecoration(
          color: GSColors.darkBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(60),
          ),
        ),
        child: ListTile(
          title: Text(title, style: TextStyle(color: Colors.white),),
          leading: Icon(icon, color: Colors.white,),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      );
    }

    return Container(
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: GSColors.darkBlue),
        ),
        leading: Icon(
          icon,
          color: GSColors.darkBlue,  
        ),
        onTap: () {_switchPage(page);},
      )
    );
  }

  void _switchPage(int page) {
    setState(() {
      _currentPage = page;
      switch (_currentPage) {
        case 0: // newfeed
        Navigator.pushReplacement(context, MaterialPageRoute<void> (
          builder: (BuildContext context) {
            return NewsfeedPage();
          }
        ));
          break;
        case 1: // workouts
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return WorkoutPlanHomePage();
            },
          ));
          break;
        case 2: // profile
          Navigator.pushReplacement(context, MaterialPageRoute<void> (
            builder: (BuildContext context) {
              return MePage();
            },
          ));
          break;
        case 3: // nutrition
          Navigator.pushReplacement(context, MaterialPageRoute<void>(
            builder: (BuildContext context){
              return NutritionPage(); 
            }
          ));
          break;
        case 4: // groups
        Navigator.pushReplacement(context, MaterialPageRoute<void> (
          builder: (BuildContext context) {
            return GroupsPage(); // Switch to groups when created
          }
        ));
          break;
        // case 5: // buddies
        // Navigator.pushReplacement(context, MaterialPageRoute(
        //   builder: (BuildContext context) {
        //     return BuddyPage(); // Switch to buddies when created
        //   }
        // ));
        //   break;
        case 5: // Notification
         Navigator.push(context, new MaterialPageRoute<void>(
            builder: (BuildContext context){
              return NotificationPage();
            }
          )); 
          break;
        case 6: // messages
          Navigator.pushReplacement(context, MaterialPageRoute<void>(
            builder: (BuildContext context){
              return MessagesPage();
              //return new Scaffold(
                //appBar: new AppBar(
                  //title: new Text("Messenger")
                //),
                //body: new MessagesPage();
              //);
            }
          ));

          break;
        case 7: // leaderboard
          Navigator.pushReplacement(context, MaterialPageRoute<void>(
            builder: (BuildContext context){
              return LeaderBoardPage();
            }
          ));

          break;

        // case 8: // settings
        //   Navigator.pushReplacement(context, MaterialPageRoute<void>(
        //     builder: (BuildContext context){
        //       return SettingsPage();
        //     }
        //   ));
        //   break;
        default:
      }
    });
  }

  void _loggedOut() async {
    try {
      await  AuthSettings.auth.signOut();
       AuthSettings.authStatus = AuthStatus.notLoggedIn;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (BuildContext context) => LoginPage(
          auth:  AuthSettings.auth,
          authStatus:  AuthSettings.authStatus,
        ),
      ));
    } catch (e) {
      print(e);
    }
  }
}