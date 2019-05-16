import 'dart:async';
import 'dart:io';
import 'package:GymSpace/global.dart';
import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/page/group_members_page.dart';
import 'package:GymSpace/page/newsfeed_page.dart';
import 'package:GymSpace/page/profile_page.dart';
import 'package:GymSpace/page/workout_plan_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/logic/group.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:GymSpace/page/notification_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class GroupProfilePage extends StatefulWidget {
  final Group group;

  GroupProfilePage({
    this.group,
    Key key}) : super(key: key);

  _GroupProfilePageState createState() => _GroupProfilePageState();
}

class _GroupProfilePageState extends State<GroupProfilePage> {
  Group get group => widget.group;
  String get currentUserID => DatabaseHelper.currentUserID;

  User admin;

  int _currentTab = 0;
  bool _loadingMembers = true;
  bool _joined = false;
  bool _isAdmin = false;
  bool _isEditing = false;
  
  String newName = '';
  String newPhotoURL = '';
  String newStatus = '';
  String newAbout = '';
  String newBio = '';

  List<User> members = List();
  final localNotify = FlutterLocalNotificationsPlugin();
  
  Future<void> _likeGroup() async {
    if (group.likes.contains(DatabaseHelper.currentUserID)) {
      await _unlikeGroup().then((_) {
        Fluttertoast.showToast(
          msg: 'Unliked!', 
          fontSize: 14, 
          textColor: GSColors.darkBlue
        );
      });
      return;
    }

    DatabaseHelper.updateGroup(group.documentID, {
      'likes': FieldValue.arrayUnion([DatabaseHelper.currentUserID])
    }).then((_) => setState(() => group.likes.add(currentUserID)));
    Fluttertoast.showToast(
      msg: 'Liked!', 
      fontSize: 14, 
      textColor: GSColors.darkBlue
    );
  }

  Future<void> _unlikeGroup() async {
    DatabaseHelper.updateGroup(group.documentID, {
      'likes': FieldValue.arrayRemove([DatabaseHelper.currentUserID])
    }).then((_) => setState(() => group.likes.remove(currentUserID)));
  }

  Future<void> _joinGroup() async {
    // Send notification to Admin
    print('group admin: ${group.admin}');
    User currentUser;
    User adminUser;
    var datas = await DatabaseHelper.getUserSnapshot(group.admin);
    adminUser = User.jsonToUser(datas.data);
    String userID = DatabaseHelper.currentUserID;
    DatabaseHelper.getUserSnapshot(userID).then((ds){
      setState(() {
        currentUser = User.jsonToUser(ds.data);
        NotificationPage notify = new NotificationPage();
        notify.sendNotifications('Joined Group', '${currentUser.firstName} ${currentUser.lastName} has joined ${group.name}', '${adminUser.fcmToken}','group', userID);
      });
    });

    addNewMemberToWeeklyChallenges();
    Firestore.instance.collection('groups').document(group.documentID).updateData({'members' : FieldValue.arrayUnion([DatabaseHelper.currentUserID])});

    Firestore.instance.collection('users').document(currentUserID).updateData({'joinedGroups': FieldValue.arrayUnion([group.documentID])})
      .then((ds) async {
        DocumentSnapshot userSnapshot = await DatabaseHelper.getUserSnapshot(currentUserID);
        setState(() {
          User user = User.jsonToUser(userSnapshot.data);
          user.documentID = userSnapshot.documentID;
          members.add(user);
          _joined = true;
          group.members = group.members.toList();
          group.members.add(currentUserID);
        });
      });  

  }

  void _leaveGroup() {
    Firestore.instance.collection('groups').document(group.documentID).updateData({'members' : FieldValue.arrayRemove([DatabaseHelper.currentUserID])});

    Firestore.instance.collection('users').document(currentUserID).updateData({'joinedGroups': FieldValue.arrayRemove([group.documentID])})
      .then((_) => setState(() {
        _currentTab = 0;
        members.removeWhere((user) => user.documentID == currentUserID);
        group.members = group.members.toList();
        group.members.remove(currentUserID);
        _joined = false;
      }));
  }

  void _editPressed() {
    setState(() {
      print('Editing');
      _isEditing = true;
    });
  }

  @override
  void initState() {
    super.initState();
    if (group.admin == DatabaseHelper.currentUserID) {
      setState(() => _isAdmin = true);
    }

    if (_isAdmin || group.members.contains(DatabaseHelper.currentUserID)) {
      setState(() {
        _joined = true;
      });
    }

    DatabaseHelper.getUserSnapshot(group.admin).then((ds) {
      setState(() => admin = User.jsonToUser(ds.data));
    });

    group.members.forEach((member) {
      DatabaseHelper.getUserSnapshot(member).then((ds) {
        User user = User.jsonToUser(ds.data);
        user.documentID = member;
        members.add(user);
        if (members.length == group.members.length) {
          setState(() {
            _loadingMembers = false;
          });
        }
      });
    });

    group.likes = group.likes.toList();

    // Local Notification Plugin
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
    return WillPopScope(
      onWillPop: () {
        if (_isEditing) {
          setState(() {
            _isEditing = false;
          });
        } else {
          return Future.value(true);
        }
      },
      child: Scaffold(
        appBar: _buildAppbar(),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildAppbar() {
    return AppBar(
      elevation: 0,
      actions: <Widget>[
        _isAdmin ?
          _isEditing ? Container(
            margin: EdgeInsets.all(10),
            child: FlatButton.icon(
              icon: Icon(Icons.save_alt),
              label: Text('Save'),
              textColor: Colors.white,
              color: GSColors.yellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)
              ),
              onPressed: _savePressed,
            )
          ) 
          : Container(
              margin: EdgeInsets.all(10),
              child: FlatButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit'),
                textColor: Colors.white,
                color: GSColors.yellow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)
                ),
                onPressed: _editPressed,
              )
          )
        : _joined ? Container(
          margin: EdgeInsets.all(10),
          child: FlatButton.icon(
            icon: Icon(Icons.subdirectory_arrow_left),
            label: Text('Leave'),
            textColor: Colors.white,
            color: GSColors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: _leaveGroup,
          ),
        ) : Container(
          margin: EdgeInsets.all(10),
          child: FlatButton.icon(
            icon: Icon(Icons.add),
            label: Text('Join'),
            textColor: Colors.white,
            color: GSColors.lightBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: _joinGroup,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      child: ListView(
        children: <Widget>[
          _buildHeader(),
          _buildPillNavigator(),
          _currentTab == 0 ? _buildOverviewTab() 
            : _currentTab == 1 ? _buildChallengesTab() 
            : Container(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      child: Stack(
        children: <Widget>[
          Container(
            height: 320,
            decoration: ShapeDecoration(
              color: GSColors.lightBlue,
              shadows: [BoxShadow(blurRadius: 1)],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60))
              )
            ),
            child: Container(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  group.startDate.isEmpty ? Container() :
                  Container(
                    alignment: Alignment.bottomLeft,
                    margin: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Start Date ${group.startDate}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Container(
                    alignment: group.startDate.isEmpty ? Alignment.bottomCenter : Alignment.bottomCenter,
                    child: FlatButton.icon(
                      icon: Icon(Icons.thumb_up),
                      textColor: Colors.white,
                      label: Text('${group.likes.length} Likes', style: TextStyle(fontSize: 14)),
                      onPressed: _likeGroup,
                    )
                  ),
                  // Row(
                  //   children: <Widget>[
                  //     Icon(Icons.thumb_up, color: Colors.white,),
                  //     Text(
                  //       '  ${group.likes.length} Likes',
                  //       style: TextStyle(
                  //         color: Colors.white,
                  //         fontSize: 12
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  group.endDate.isEmpty ? Container() :
                  Container(
                    alignment: Alignment.bottomRight,
                    margin: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'End Date ${group.endDate}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: ShapeDecoration(
              color: GSColors.darkBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60))
              )
            ),
            height: 280,
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget> [
                    Container( // group photo
                      decoration: ShapeDecoration(
                        shadows: [BoxShadow(color: Colors.black, blurRadius: 4, spreadRadius: 2)],
                        shape: CircleBorder(
                          side: BorderSide(color: Colors.white, width: .5),
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: group.photoURL.isNotEmpty ? CachedNetworkImageProvider(group.photoURL)
                        : AssetImage(Defaults.userPhoto),
                        radius: 80,
                        child: _isEditing ? Container(
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: CircleBorder(
                              side: BorderSide()
                            )
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.cloud_upload,
                              color: GSColors.darkBlue,
                            ),
                            onPressed: _editGroupPic,
                          )
                        ) : null,
                      ),
                    ),
                  ]
                ),
                Divider(color: Colors.transparent, height: 4,),
                Container( // name
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isEditing ? Colors.white : Colors.transparent,
                      width: 1
                    )
                  ),
                  child: InkWell(
                    onTap: _isEditing ? _editName : () {},
                    child: Text(
                      group.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                  )
                ),
                Divider(color: Colors.transparent, height: 4,),
                Container( // instructor
                  child: FutureBuilder(
                    future: DatabaseHelper.getUserSnapshot(group.admin),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Instructed by ${snapshot.data['firstName']} ${snapshot.data['lastName']}  ',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          Container(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => ProfilePage(forUserID: group.admin,)
                                ));
                              },
                              child: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(snapshot.data['photoURL']),
                                radius: 10,
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
                Divider(color: Colors.transparent, height: 2),
                Container( // status
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isEditing ? Colors.white : Colors.transparent,
                      width: 1
                    )
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 80),
                  child: InkWell(
                    onTap: _isEditing ? _editStatus : () {},
                    child: Text(
                      group.status,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    )
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillNavigator() {
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: ShapeDecoration(
        color: GSColors.darkBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40)
        ),
        // shadows: [BoxShadow()],
      ),
      child: Row(
        mainAxisAlignment: _joined ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
        children: <Widget>[
          Container(
            child: MaterialButton( // overview
              onPressed: () { 
                if (_currentTab != 0) {
                  setState(() => _currentTab = 0);
                }
              },
              child: Text(
                'Overview',
                style: TextStyle(
                color: _currentTab == 0 ? Colors.white : Colors.white54,
                fontSize: 14,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              )),
            ),
          ),

          _joined ? Container(
            child: MaterialButton( // Challenges
              onPressed: () { 
                if (_currentTab != 1) {
                  setState(() => _currentTab = 1);
                }
              },
              child: Text(
                'Challenges',
                style: TextStyle(
                color: _currentTab == 1 ? Colors.white : Colors.white54,
                fontSize: 14,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              )),
            ),
          ) : Container(),

          _joined ? Container(
            child: MaterialButton( // Discussion
              onPressed: () { 
                if (_currentTab != 2) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => NewsfeedPage(forGroup: group,)
                  ));
                  // setState(() => _currentTab = 2);
                }
              },
              child: Text(
                'Discussion',
                style: TextStyle(
                color: _currentTab == 2 ? Colors.white : Colors.white54,
                fontSize: 14,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              )),
            ),
          ) : Container(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Container(
      child: Column(
        children: <Widget>[
          _buildAbout(),
          _buildMembersList(),
          _joined ? _buildWorkouts() : Container(),
        ],
      )
    );
  }

  Widget _buildAbout() {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: 20,),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
        color: GSColors.darkBlue,
        // shadows: [BoxShadow(blurRadius: 1)]
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Text(
                'About',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, bottom: 20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isEditing ? Colors.white : Colors.transparent,
                  // width: 1,
                )
              ),
              child: InkWell(
                onTap: _isEditing ? _editBio : () {},
                child: Text(
                  group.bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            )
          ],
        ),
      )
    );
  }

  Widget _buildMembersList() {
    return InkWell(
      child: Container(
        width: double.maxFinite,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: ShapeDecoration(
          color: GSColors.darkBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(60),
          ),
          // shadows: [BoxShadow(blurRadius: 1.5)]
        ),
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Text(
                ' ${group.members.length} Members',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 1.2,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: _loadingMembers ? 
              CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(GSColors.babyPowder), 
              ) :
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildMemberAvatars(),
              )
            )
          ],
        ),
      ),
      onTap: () => _loadingMembers ? null : Navigator.push(context, MaterialPageRoute(
        builder: (context) => GroupMembersPage(group: group, members: members),
      )),
    );
  }

  List<Widget> _buildMemberAvatars() {
    List<Widget> memberAvatars = List();

    for (User member in members) {
      memberAvatars.add(
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: ShapeDecoration(
            shape: CircleBorder(
              side: BorderSide(color: Colors.white)
            )
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: member.photoURL.isNotEmpty ? CachedNetworkImageProvider(member.photoURL)
            : AssetImage(Defaults.userPhoto),
            radius: 20,
          ),
        )
      );

      if (memberAvatars.length == 5) {
        break;
      }
    }

    if (members.length <= 5) {
      return memberAvatars;
    }

    memberAvatars.add(
      Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: CircleAvatar(
          backgroundColor: GSColors.purple,
          child: Text(
            '+${members.length - 4}',
            style: TextStyle(
              color: Colors.white
            ),
          ),
          radius: 21, // 21 because border of circle avatars were of width 1
        ),
      )
    );
    return memberAvatars;
  }

  Widget _buildWorkouts() {
    return Container(
      child: FlatButton.icon(
        textColor: GSColors.darkBlue,
        icon: Icon(Icons.keyboard_arrow_right),
        label: Text('Workouts', style: TextStyle(fontSize: 24, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => WorkoutPlanHomePage(forGroup: group.documentID, isGroupAdmin: group.admin == currentUserID)
          )
        ),
      ),
    );
  }

  Widget _buildChallengesTab() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          _buildChallenges(),
          _buildLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildChallenges() {
      String _challengeKey = getChallengeKey(); //challenge weekly date
      String challengeTitle, challengeUnits;
      int challengeGoal, challengePoints;
      GlobalKey<FormState> formKey = GlobalKey();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: <Widget>[
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget> [
                Text(
                  'Weekly Challenges',
                  style: TextStyle(
                    fontSize: 22,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold
                  ),
                ), 
                //check if admin
               _isAdmin ? 
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context){
                        return AlertDialog(
                          title: Text("For Week:  " + _challengeKey),
                          content:
                            Container(
                              height: 450,
                              width: 350,
                              //child: Scrollbar(
                              child: ListView(
                                children: <Widget>[
                                  Form(
                                  key: formKey,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      
                                      TextFormField(//challenge Title
                                        decoration: InputDecoration(
                                          icon: Icon( FontAwesomeIcons.angleRight,
                                          color: GSColors.darkBlue,
                                          size: 30,),
                                          hintText: "e.g Run 20 miles",
                                          labelText: "Challenge Name"
                                        ),
                                        onSaved: (name) => challengeTitle = name,
                                        validator: (value) => value.isEmpty ? "This field cannot be empty" : null,
                                        textCapitalization: TextCapitalization.sentences
                                      ),

                                      TextFormField(//units
                                        decoration: InputDecoration(
                                          icon: Icon( FontAwesomeIcons.angleRight,
                                          color: GSColors.darkBlue,
                                          size: 30,),
                                          hintText: "e.g Miles",
                                          labelText: "Units"
                                        ),
                                        onSaved: (units) => challengeUnits = units,
                                        validator: (value) => value.isEmpty ? "This field cannot be empty" : null,
                                        textCapitalization: TextCapitalization.sentences,
                                      ), 

                                      TextFormField(//goal
                                        decoration: InputDecoration(
                                          icon: Icon( FontAwesomeIcons.angleRight,
                                          color: GSColors.darkBlue,
                                          size: 30,),
                                          hintText: "e.g 20",
                                          labelText: "Goal"
                                        ),
                                        onSaved: (goal) => challengeGoal = int.parse(goal),
                                        validator: (value) => value.isEmpty ? "This field cannot be empty" : null,
                                        textCapitalization: TextCapitalization.sentences,
                                        keyboardType: TextInputType.number

                                      ), 

                                       TextFormField(//points
                                        decoration: InputDecoration(
                                          icon: Icon( FontAwesomeIcons.angleRight,
                                          color: GSColors.darkBlue,
                                          size: 30,),
                                          hintText: "e.g 100",
                                          labelText: "Points upon completion"
                                        ),
                                        onSaved: (points) => challengePoints = int.parse(points),
                                        validator: (value) => value.isEmpty ? "This field cannot be empty" : null,
                                        textCapitalization: TextCapitalization.sentences,
                                        keyboardType: TextInputType.number
                                      ), 
                                       

                                    ],
                                  )
                                  )
                                ],
                              ),
                             // )
                            ),
                            actions: <Widget>[
                              FlatButton(
                                child: const Text('Cancel'),
                                onPressed: (){
                                  Navigator.pop(context);
                                },
                              ),
                              FlatButton(
                                child: const Text('Save'),
                                onPressed: (){
                                  if(formKey.currentState.validate())
                                  {
                                    formKey.currentState.save();
                                    Map<String, dynamic> newGroupChallenge;    
                                    Map<String, dynamic> membersMap = Map();

                                    for(int i = 0; i < group.members.length; i++)
                                    {
                                      membersMap[group.members[i]] = {'points': 0, 'progress' : 0};
                                    }

                                    newGroupChallenge =  
                                        {'points' : challengePoints, 
                                          'units' : challengeUnits,
                                          'goal' : challengeGoal,
                                          'members' : membersMap//membersMapList
                                          };         

                                    _uploadGroupChallenge(newGroupChallenge, _challengeKey, challengeTitle);
                                    Navigator.pop(context);
                                  }
                                }
                              )
                            ],
                        );
                      }
                    );
                  },
                )
             : Container(),
              ],
            ),
          ),
          //Container(
          InkWell(
            onTap: (){
              if (_isAdmin) {
                return;
              }
              
              showDialog(
                context: context,
                builder: (BuildContext context)
                {
                  List<int> inputList = List();
                  List<String> challengeNames = List();
                  return AlertDialog(
                    title: Text(
                      "Update your progress on your group's weekly challenges"),
                    content: 
                    Container(
                      width: double.maxFinite,
                      // child: Scrollbar(
                        child: ListView(

                        // child: StreamBuilder(
                          children: <Widget>[
                            
                          StreamBuilder(
                          stream:  DatabaseHelper.getGroupStreamSnapshot(group.documentID),
                          builder: (context, snapshotGroup){
                            if(snapshotGroup.data == null || snapshotGroup.data.data['challenges'][_challengeKey] == null)
                            {
                              return Container();
                            }
                            else
                            {
                              List<Widget> challengeList = [];
                              // int userIndex;
                              snapshotGroup.data.data['challenges'][_challengeKey].cast<String, dynamic>().forEach((title, value){                          
                              
                                // for(int i = 0; i < group.members.length; i++)
                                // {
                                //   if(value['members'][i] == DatabaseHelper.currentUserID)
                                //     userIndex = i;
                                // }
                                challengeList.add(
                                  TextField(
                                    decoration: InputDecoration(
                                      labelText: title,
                                      labelStyle: TextStyle(
                                        fontSize: 18.0,
                                        color: GSColors.darkBlue
                                        ),
                                      contentPadding: EdgeInsets.all(10.0),
                                      hintText: '${value['members'][DatabaseHelper.currentUserID]['progress'].toString()}/${value['goal'].toString()} ${value['units']} Completed',
                                      hintStyle: TextStyle(
                                        color: GSColors.lightBlue,
                                        fontWeight: FontWeight.bold,
                                        ),
                                      counterText: ""
                                      ),
                                      maxLength: 5,
                                      onChanged: (text){
                                        (text != null) ? inputList.add(int.parse(text)) : inputList.add(-999999);
                                        challengeNames.add(title);
                                      },
                                  )
                                );
                              });
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: challengeList,
                              );
                            }
                          }
                        ),
                          ]
                        )
                    ),
                    actions: <Widget>[
                      FlatButton(
                        child: const Text('Cancel'),
                        onPressed: (){
                          Navigator.pop(context);
                        },
                      ),
                      FlatButton(
                        child: const Text('Save'),
                        onPressed: (){
                          _updateMemberChallengeProgress(inputList, challengeNames);
                          _buildChallenges();
                          Navigator.pop(context);
                        },
                      )

                    ],
                  );
                }
              );
            },
            child: Container(
            width: double.maxFinite,
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: ShapeDecoration(
              color: GSColors.darkBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              )
            ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  StreamBuilder(
                    stream: DatabaseHelper.getGroupStreamSnapshot(group.documentID),
                    builder: (context, snapshotGroup){
                      if(!snapshotGroup.hasData || snapshotGroup.data.data['challenges'][_challengeKey] == null)
                      {
                        return Container();
                      }
                      else
                      {
                        List<Widget> challengeList = [];
                        snapshotGroup.data.data['challenges'][_challengeKey].cast<String, dynamic>().forEach((title, value)
                        {
                          if (_isAdmin) {
                            challengeList.add(
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              )
                            );
                            return Column(
                              // crossAxisAlignment: CrossAxisAlignment.start,
                              children: challengeList,
                            );
                          }
                          if(value['members'][DatabaseHelper.currentUserID]['progress'] == value['goal'])
                          {
                            challengeList.add(
                              Container(
                              margin: EdgeInsets.fromLTRB(15, 15, 15, 15),
                              child :Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                Container(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: GSColors.cloud,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Container(
                                    height: 20,
                                    child: (LinearPercentIndicator(
                                    width: 330,
                                    lineHeight: 14.0,
                                    percent: 1.0,
                                    backgroundColor: Colors.green,
                                    progressColor: Colors.green,
                                    center: Text("100%")
                                    )  
                                  ),  
                                )
                              ]
                            )
                              )
                            );
                          }
                          else{
                            challengeList.add(
                              Container(
                              margin: EdgeInsets.fromLTRB(15, 15, 15, 15),
                              child :Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                Container(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: GSColors.cloud,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Container(
                                    height: 20,
                                    child: (LinearPercentIndicator(
                                    width: 330,
                                    lineHeight: 14.0,
                                    percent: value['members'][DatabaseHelper.currentUserID]['progress']/value['goal'],
                                    backgroundColor: GSColors.darkCloud,
                                    progressColor: GSColors.lightBlue,
                                    center: Text((value['members'][DatabaseHelper.currentUserID]['progress']/value['goal'] * 100).toStringAsFixed(0) + "%")
                                    )  
                                  ),  
                                )
                              ]
                            )
                              )
                            );
                          }                   
                        });               
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: challengeList,                                                            
                        );
                      }
                    },
                  ),            
                ],
              ),
            )
          )
        ],
      ),
    );
  }


//new user joins after weekly challenge is posted
Future<void> addNewMemberToWeeklyChallenges() async {
  DocumentSnapshot groupChallenge = await Firestore.instance.collection('groups').document(group.documentID).get();
  String _challengeKey = getChallengeKey();
  Map challengeMap = groupChallenge.data['challenges'];
  if (challengeMap[_challengeKey] == null) 
    return;

  challengeMap[_challengeKey].cast<String, dynamic>().forEach((title, value)
  {
    value['members'][DatabaseHelper.currentUserID] = {'points' : 0, 'progress' : 0};
  });

  Firestore.instance.collection('groups').document(group.documentID).updateData(
      {'challenges' : challengeMap}
  ).then((_) => setState);
}


Future<void> _updateMemberChallengeProgress(List<int> progressList, List<String> challengeName) async{
  DocumentSnapshot groupChallenge = await Firestore.instance.collection('groups').document(group.documentID).get();
  int temp, userPoints, groupPoints, newProgress;
  String _challengeKey = getChallengeKey(); //challenge weekly date
  //DocumentSnapshot userInfo = await Firestore.instance.collection('user').document(DatabaseHelper.currentUserID).get();
  DocumentSnapshot userInfo = await DatabaseHelper.getUserSnapshot(DatabaseHelper.currentUserID);

  Map challengeMap = groupChallenge.data['challenges'];// = groupChallenge.data['challenges'][_challengeKey];

  for(int i = 0; i < progressList.length; i++)
  {
    if(progressList[i] == -999999)
      progressList[i] = 0;

      //print(challengeName[0]);
      print(challengeName.length);

      temp = progressList[i] + groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['members'][DatabaseHelper.currentUserID]['progress'];

      if(progressList[i] != 0 && temp >= groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['goal'] && groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['members'][DatabaseHelper.currentUserID]['progress'] != groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['goal'])
      {
        userPoints = groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['points'] + userInfo.data['points'];
        groupPoints = groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['points'];
        newProgress = groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['goal'];
        
        challengeMap[_challengeKey][challengeName[i]]['members'][DatabaseHelper.currentUserID]['points'] = groupPoints;
        challengeMap[_challengeKey][challengeName[i]]['members'][DatabaseHelper.currentUserID]['progress'] = newProgress;


        Firestore.instance.collection('groups').document(group.documentID).updateData(
          {'challenges' : challengeMap}
          );
        Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
          {'points' : userPoints}
          );
      }

      else if(progressList[i] != 0 && groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['goal'] != groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['members'][DatabaseHelper.currentUserID]['progress'])
      {
        newProgress = groupChallenge.data['challenges'][_challengeKey][challengeName[i]]['members'][DatabaseHelper.currentUserID]['progress']
                    + progressList[i];

        challengeMap[_challengeKey][challengeName[i]]['members'][DatabaseHelper.currentUserID]['progress'] = newProgress;
        Firestore.instance.collection('groups').document(group.documentID).updateData(
          {'challenges' : challengeMap}
          );
      }


  }
}

  Future<void> _uploadGroupChallenge(Map challengeInfo, String challengeKey, String challengeTitle) async
  {
    DocumentSnapshot groupChallengeSnap = await Firestore.instance.collection('groups').document(group.documentID).get();
    Map<String, dynamic> challengeMap = groupChallengeSnap.data['challenges'].cast<String, dynamic>();
    Map<String, dynamic> newWeekMap = Map();

    if(challengeMap[challengeKey] == null)
    {
      newWeekMap = {challengeKey: {}};
      Firestore.instance.collection('groups').document(group.documentID).updateData(
      {'challenges' : newWeekMap  }
      );

      _uploadGroupChallenge(challengeInfo, challengeKey, challengeTitle);
    }

    else{
    challengeMap[challengeKey][challengeTitle] = challengeInfo;
    
    Firestore.instance.collection('groups').document(group.documentID).updateData(
      {'challenges' : challengeMap}
      );
    }
  }


  String getChallengeKey(){
  
  DateTime now = DateTime.now();
  int sunday = 7;

  while(now.weekday != sunday)
  {
    now = now.subtract(Duration(days: 1));
  }

  return now.toString().substring(0,10);
} 

  Widget _buildLeaderboard() {
    return Container(
      //height: 200,
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: ShapeDecoration(
        color: GSColors.darkBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        )
      ),
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Leaderboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.fromLTRB(15, 0, 15, 20),
            child: StreamBuilder(
              stream:  DatabaseHelper.getGroupStreamSnapshot(group.documentID),
               builder: (context, snapshotGroup){
               
                 String _challengeKey = getChallengeKey();

                if(!snapshotGroup.hasData || snapshotGroup.data.data['challenges'][_challengeKey] == null)//snapshotGroup.data.data['challenges'][_challengeKey] != null)
                {
                  return Container();
                }
              
                else
                {
                  List<Widget> leaderBoardList = List();
                  List<Map> memberPointsList = List(group.members.length);
                  List<Map> finalPointsList = List();
                  //Map<String, int> memberPointsMap = Map();
                  int i = 0;
                  int tmpPoints = 0;


                  //initialize list
                  for(int j = 0; j < members.length; j++)
                  {
                    memberPointsList[j] = {'userID' : members[j].documentID, 'points' : 0, 'name' : members[j].firstName + " " + members[j].lastName, 'avatar' : members[j].photoURL};
                    print(memberPointsList[j]);
                  }
          
                 snapshotGroup.data.data['challenges'][_challengeKey].cast<String, dynamic>().forEach((title, subMap0){
                   subMap0['members'].cast<String, dynamic>().forEach((memberName, memberInfo) {
                    
                      for(int j = 0; j < memberPointsList.length; j++)
                      {
                        if(memberPointsList[j]['userID'] == memberName)
                        {
                          tmpPoints = memberInfo['points'] + memberPointsList[j]['points'];
                          memberPointsList[j] = {'userID' : memberName, 'points' : tmpPoints, 'name' : memberPointsList[j]['name'], 'avatar' : memberPointsList[j]['avatar']};
                        }
                      }
                   });
                 });

                  for(int i = 0; i < memberPointsList.length; i++)
                  {
                    print(memberPointsList[i]);
                  }
                  
                  //sort  based on points
                  memberPointsList.sort((a, b) => a['points'].compareTo(b['points']));
                  for(int j = memberPointsList.length - 1; j >= 0; j--)
                  {

                    leaderBoardList.add(
                      Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                        
                        Container(
                          decoration: ShapeDecoration(
                            shape:  CircleBorder(
                              side: BorderSide(
                                color: Colors.white
                              )
                            )
                          ),
                          child: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                              memberPointsList[j]['avatar'].isEmpty ? Defaults.userPhotoDB : memberPointsList[j]['avatar']
                              ),
                              radius: 20,
                          ),
                        ),

                        Container(
                          margin: EdgeInsets.only(left: 7),
                          child: Text(
                            memberPointsList[j]['name'],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: GSColors.cloud,
                              fontSize: 18,
                              fontWeight: FontWeight.w500
                            ),
                          )
                        ),
                        
                        Spacer(flex: 1),

                        Container(
                          margin: EdgeInsets.only(right: 0),
                          child: Text(
                            memberPointsList[j]['points'].toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: GSColors.cloud,
                              fontSize: 18
                            ),
                          )
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.stars,
                            size: 14,
                            color: Colors.yellow,
                          )
                        )
                      ],)
                      )
                    );


                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: leaderBoardList,

                  );
                }
               }
            )
          )
          // SHOW ACTUAL CONTENT HERE
        ],
      ),
    );
  }

  Widget _buildDiscussionTab() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: NewsfeedPage(forGroup: group,),
    );
  }

  // Methods to update the group
  Future<void> _savePressed() async {
    if (newPhotoURL.isEmpty)
      newPhotoURL = group.photoURL;

    if (newName.isEmpty) 
      newName = group.name;

    if (newStatus.isEmpty)
      newStatus = group.status;   
    
    if (newBio.isEmpty)
      newBio = group.bio;

    await DatabaseHelper.updateGroup(group.documentID, {
      'photoURL': newPhotoURL,
      'name': newName,
      'status': newStatus,
      'bio': newBio,
    }).then((_) {
      setState(() {
        group.photoURL = newPhotoURL;
        group.name = newName;
        group.status = newStatus;
        group.bio = newBio;
        _isEditing = false;
      });
    }).catchError((e) {
      print('Failed to save edits');
      setState(() {
        _isEditing = false;
      });
    });
  }

  Future<void> _editGroupPic() async {
    File newImage = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (newImage == null) {
      return;
    }

    // upload the image
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(newImage);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;

    await storageTaskSnapshot.ref.getDownloadURL().then((downloadURL) {
      newPhotoURL = downloadURL;
      print('new photo url: $newPhotoURL');
    }).catchError((e) => Fluttertoast.showToast(msg: 'This file is not an image'));
  }

  Future<void> _editName() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 10),
          content: Container(
            child: TextField(
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: group.name,
              ),
              onChanged: (value) => newName = value,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                newName = '';
                Navigator.pop(context);
              }
            ),
            FlatButton(
              child: Text('Okay'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      }
    );
  }

  Future<void> _editStatus() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 10),
          content: Container(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Update Status',
                hintText: group.status,
              ),
              onChanged: (value) => newStatus = value,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
                newStatus = '';
              }
            ),
            FlatButton(
              child: Text('Okay'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      }
    );
  }

Future<void> _editBio() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 10),
          content: Container(
            child: TextField(
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Update Description',
                hintText: group.bio,
              ),
              onChanged: (value) => newBio = value,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
                newBio = '';
              }
            ),
            FlatButton(
              child: Text('Okay'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      }
    );
  }
}