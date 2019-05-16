import 'dart:async';

import 'package:GymSpace/global.dart';
import 'package:GymSpace/logic/group.dart';
import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/page/profile_page.dart';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupMembersPage extends StatefulWidget {
  final Group group;
  List<User> members;
  
  GroupMembersPage({
    @required this.group,
    @required this.members,
    Key key
  }) : super(key: key);

  _GroupsMembersPageState createState() => _GroupsMembersPageState();
}

class _GroupsMembersPageState extends State<GroupMembersPage> {
  Group get group => widget.group;
  List<User> get members => widget.members;

  void _memberLongPressed(User member) {
    if (group.admin == DatabaseHelper.currentUserID) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)
            ),
            title: Text('Remove from ${group.name}?'),
            content: Text(
              'Are you sure you want to remove ${member.firstName} from the group?',
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              FlatButton(
                onPressed: () => _removeMemberFromGroup(member),
                child: Text('Remove'),
              )
            ],
          );
        }
      );
    }
  }

  Future<void> _removeMemberFromGroup(User member) async {
    print('Removing ${member.firstName} ${member.lastName} from the group: ${group.name}');
    
    Firestore.instance.collection('groups').document(group.documentID).updateData({
      'members': FieldValue.arrayRemove([member.documentID])
    }).then((ds) {
      Firestore.instance.collection('users').document(member.documentID).updateData({
        'joinedGroups': FieldValue.arrayRemove([group.documentID])
      }).then((_) {
        print('Successfully removed ${member.firstName} ${member.lastName} from the group: ${group.name}');
        setState(() {
          group.members = group.members.toList();
          group.members.remove(member.documentID);
          widget.members = members.toList();
          widget.members.remove(member);
        });
        
        Firestore.instance.collection('groups').document(group.documentID).updateData({
          'likes': FieldValue.arrayRemove([member.documentID])
        });
      });
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: PageHeader(
        backgroundColor: GSColors.darkBlue,
        title: '${members.length} Members',
        titleColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      margin: EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: GSColors.darkBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(60)
        )
      ),
      child: Container(
        margin: EdgeInsets.only(top: 20),
        child: GridView.builder(
          itemCount: members.length,
          itemBuilder: (context, i) {
            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => ProfilePage.fromUser(members[i])
              )),
              onLongPress: () => _memberLongPressed(members[i]),
              child: Container(
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundImage: members[i].photoURL.isNotEmpty ? CachedNetworkImageProvider(members[i].photoURL)
                      : AssetImage(Defaults.userPhoto),
                    ),
                    Divider(color: Colors.transparent,),
                    Text(
                      '${members[i].firstName} ${members[i].lastName}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        letterSpacing: 1.2
                      ),
                    )
                  ],
                ),
              ),
            );
          },
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
        ),
      ),
    );
  }
}