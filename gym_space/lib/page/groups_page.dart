import 'package:GymSpace/global.dart';
import 'package:GymSpace/logic/group.dart';
import 'package:GymSpace/page/group_profile_page.dart';
import 'package:GymSpace/page/search_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/widgets/app_drawer.dart';
import 'package:GymSpace/page/notification_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

import 'package:fluttertoast/fluttertoast.dart';

class GroupsPage extends StatefulWidget {
  final Widget child;

  GroupsPage({Key key, this.child}) : super(key: key);

  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final localNotify = FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
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

  void _searchPressed(BuildContext context) async {
    List<Group> allGroups = List();
    QuerySnapshot groupSnapshots = await Firestore.instance.collection('groups').getDocuments();
    groupSnapshots.documents.forEach((ds) {
      // print(ds.data);
      Group group = Group.jsonToGroup(ds.data);
      group.documentID = ds.documentID;
      allGroups.add(group);
    });

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => SearchPage(
        searchType: SearchType.group,
        groups: allGroups,
      )
    ));
  }

  Future<void>_addGroup(Group group) async {
    return Firestore.instance.collection('groups').add(group.toJSON()).then(
      (ds) => Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
        {'joinedGroups': FieldValue.arrayUnion([ds.documentID])}
      )
    );
  }

  void _addPressed(BuildContext context) {
    Group newGroup = Group(
      admin: DatabaseHelper.currentUserID,
      name: '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)
          ),
          content: Container(
            // width: double.maxFinite,
            height: 170,
            child: Center(
              child: _buildForm(newGroup),
            )
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                _formKey.currentState.reset();
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text('Create'),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  _addGroup(newGroup).then((_) => Navigator.pop(context));
                }
              },
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(startPage: 4),
      // backgroundColor: GSColors.olive,
      appBar: _buildAppBar(context),
      // body: _buildGroupBackground(),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPressed(context),
        backgroundColor: GSColors.purple,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: PageHeader(
        title: 'Your Groups',
        backgroundColor: GSColors.darkBlue,
        showDrawer: true,
        showSearch: true,
        searchFunction: () => _searchPressed(context),
        titleColor: Colors.white,
      )
    );
  }


  Widget _buildBody(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      // color: Colors.white
      child: FutureBuilder(
        future: DatabaseHelper.getCurrentUserGroups(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          
          return GridView.builder(
            itemCount: snapshot.data.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, i) {
              return StreamBuilder(
                stream: DatabaseHelper.getGroupStreamSnapshot(snapshot.data[i]),
                builder: (context, groupSnap) {
                  if (!groupSnap.hasData) {
                    return Container();
                  }

                  if (groupSnap.data.data == null) {
                    return Container();
                  }

                  Group joinedGroup = Group.jsonToGroup(groupSnap.data.data);
                  joinedGroup.documentID = groupSnap.data.documentID;
                  return _buildGroupItem(joinedGroup);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _groupLongPressed(Group group) {
    if (group.admin != DatabaseHelper.currentUserID) 
      return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FlatButton.icon(
                icon: Icon(Icons.delete),
                label: Text('Delete'),
                textColor: GSColors.red,
                onPressed: () => _deleteGroupPressed(group),
              )
            ],
          ),
        );
      }
    );
  }

  void _deleteGroupPressed(Group group) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text('Are you sure?'),
                  FlatButton.icon(
                    icon: Icon(Icons.cancel),
                    textColor: GSColors.red,
                    label: Text('No'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FlatButton.icon(
                    icon: Icon(Icons.check),
                    textColor: GSColors.green,
                    label: Text('Yes'),
                    onPressed: () => _deleteGroup(group)
                  ),
                ],
              )
            ],
          )
        );
      }
    );
  }

  void _deleteGroup(Group group) {
    Navigator.pop(context);
    Firestore.instance.collection('groups').document(group.documentID).delete()
      .then((_) => Fluttertoast.showToast(msg: 'Removed Group'));
    
    DatabaseHelper.updateUser(DatabaseHelper.currentUserID, {'joinedGroups': FieldValue.arrayRemove([group.documentID])});
  }

  Widget _buildGroupItem(Group group) {
    return Container(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => GroupProfilePage(group: group) 
          )
        ),
        onLongPress: () => _groupLongPressed(group),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)
          ),
          child: Container(
            decoration: ShapeDecoration(
              image: DecorationImage(
                image: group.photoURL.isNotEmpty ? CachedNetworkImageProvider(group.photoURL)
                : AssetImage(Defaults.groupPhoto),
                fit: BoxFit.cover,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              )
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                    )
                  ),
                  child: Text(
                    group.name,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      // letterSpacing: 1.2
                    ),
                  ),
                ),
                // Container(
                //   alignment: Alignment.topRight,
                //   child: Container(
                //     constraints: BoxConstraints.tight(Size.fromRadius(14)),
                //     decoration: ShapeDecoration(
                //       color: Colors.red,
                //       shape: CircleBorder(),
                //     ),
                //     child: InkWell(
                //       child: Icon(Icons.cancel, color: Colors.white,),
                //       onTap: () {},
                //     ),
                //   )
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Group group) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(
              hintText: 'New Group',
              labelText: 'Group Name',
            ),
            onSaved: (name) => group.name = name,
            validator: (text) => text.isEmpty ? 'Please enter a group name' : null,
          ),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Description ',
              labelText: 'Bio',
            ),
            onSaved: (bio) => group.bio = bio,
            validator: (text) => text.isEmpty ? 'Please enter a group description' : null,
          ),
        ],
      ),
    );
  }

}