import 'dart:async';
import 'dart:io';
import 'package:GymSpace/global.dart';
import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/page/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/widgets/app_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:GymSpace/widgets/page_header.dart';




class LeaderBoardPage extends StatefulWidget{

  LeaderBoardPage({
    Key key}) : super(key: key);

  _LeaderBoardPageState createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage>{
  bool _isLoading = true;
  List<User> userList0 = List();
  List<User> userList = List();

  @override
  void initState() {
    super.initState();
    makeUserList();
  }

  @override 
  Widget build(BuildContext context){
    return Scaffold(
      drawer: AppDrawer(startPage: 7,),
      appBar: _buildAppBar(),//AppBar(elevation: 0,),
      body: _buildBody(),
      backgroundColor: GSColors.darkBlue,
    );
  }

  Future<List<User>> makeUserList() async{
    // List<User> userList = List();
    QuerySnapshot userSnapshots = await Firestore.instance.collection('users').getDocuments();
    userSnapshots.documents.forEach((ds) {
      User user = User.jsonToUser(ds.data);
      user.documentID = ds.documentID;
      userList0.add(user);
    });

    userList0.sort((a, b) => a.points.compareTo(b.points));
    userList = userList0.reversed.toList();
    setState(() {
     _isLoading = false; 
    });
    return userList;
  }


 Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: PageHeader(
        title: 'Leaderboard', 
        backgroundColor: Colors.white, 
        showDrawer: true,
        titleColor: GSColors.darkBlue,
      )
    );  
  }


  Widget _buildLeaderContent(){
    if (_isLoading) {
      return Container();
    }
      int counter = 0;
      List<Widget> leaderList = [];
      for(int i = 0; i < userList.length; i++)
      {
        // String count = counter.toString().padLeft(2);
        if(userList[i].private == false)
        { 
          counter++;
          
          leaderList.add(
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Text(
                      counter < 10 ? '$counter.     ' : '$counter.  ',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: GSColors.cloud,
                        fontSize: 18,
                        fontWeight: FontWeight.w500
                      ),
                    )
                  ),

                  Container(
                    // margin: EdgeInsets.only(left: 4),
                    decoration: ShapeDecoration(
                      shape:  CircleBorder(
                        side: BorderSide(
                          color: Colors.white
                        )
                      )
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (context) => ProfilePage.fromUser(userList[i]),
                      )),
                      child: CircleAvatar(
                        backgroundImage: userList[i].photoURL.isNotEmpty ? CachedNetworkImageProvider(userList[i].photoURL)
                            : AssetImage(Defaults.userPhoto),
                        radius: 20,
                      ),
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.only(left: 10),
                    child: Text(
                      userList[i].firstName + " " + userList[i].lastName,
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
                      userList[i].points.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: GSColors.cloud,
                        fontSize: 18
                      ),
                    )
                  ),
                  
                  Container(
                    margin: EdgeInsets.only(left: 7),
                    padding: EdgeInsets.only(right: 15),
                    child: Icon(
                      Icons.stars,
                      size: 14,
                      color: GSColors.yellowCoin,
                    )
                  )
                  ]
              )
            )
          );
        }
      }
      return Container(
        child: Column(
          children: leaderList,
        )
      );
  }
  

  Widget _buildBody() {
    return Container(
        padding: EdgeInsets.only(top: 25),
        margin: EdgeInsets.only(left: 10),
        child: ListView(
          children: <Widget>[
            _buildLeaderContent(),
          ],
        ),
      );

  }
}