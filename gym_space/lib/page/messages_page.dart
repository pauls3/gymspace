import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/page/message_thread_page.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:GymSpace/widgets/app_drawer.dart';
import 'package:GymSpace/global.dart';

class MessagesPage extends StatelessWidget {
  // Change to MessagesPage() - Must be StatelessWidget that returns a Scaffold - move to page folder

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    if (document['userID'] == FirebaseAuth.instance.currentUser()) {
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: CachedNetworkImage(
                  placeholder: (context, text) => Container(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.0,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(GSColors.darkBlue),
                    ),
                    width: 50.0,
                    height: 50.0,
                    padding: EdgeInsets.all(15.0),
                  ),
                  imageUrl: document['photoURL'].isEmpty ? Defaults.userPhotoDB : document['photoURL'],
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              new Flexible(
                child: Container(
                  child: new Column(
                    children: <Widget>[
                      new Container(
                        child: Text(
                          '${document['firstName']} ${document['lastName']}',
                          style: TextStyle(color: GSColors.cloud),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: new EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                      ),
                      new Container(
                        child: Text(
                          ' ${document['bio'] ?? 'Not available'}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: GSColors.cloud,
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: new EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20.0),
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) => new MessageThreadPage(
                          peerId: document.documentID,
                          peerAvatar: document['photoURL'] ?? Defaults.userPhotoDB,
                          peerFirstName: document['firstName'],
                          peerLastName: document['lastName'],
                        )));
          },
          color: GSColors.darkBlue,
          padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
          // shape: OutlineInputBorder(
          //   borderRadius:  BorderRadius.circular(50),
          // )
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        startPage: 6,
      ),
      appBar: _buildAppBar(),
      // floatingActionButton: new FloatingActionButton(
      //   //IconButton(
      //   elevation: 1.0,
      //   child: new Icon(Icons.adb),
      //   onPressed: ,

      //   ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List
            Container(
              child: FutureBuilder(
                // stream: Firestore.instance.collection('users').snapshots(),
                future: DatabaseHelper.getCurrentUserBuddies(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(GSColors.darkBlue),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder(
                          future: DatabaseHelper.getUserSnapshot(snapshot.data[index]),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return buildItem(context, snapshot.data);
                            } else {
                              return Container();
                            }
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
        onWillPop: null,
      ),
    );
  }

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: PageHeader(
        title: "Messages",
        backgroundColor: GSColors.darkBlue,
        showDrawer: true,
        titleColor: Colors.white,
      ),
    );
  }
}
