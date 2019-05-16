import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../global.dart';

class ImageWidget extends StatelessWidget {
  final String media;
  final BuildContext context;
  final bool _private;
  User user;

  ImageWidget(this.media, this.context, this._private, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if(_private) 
      return _buildPrivateImage();
    else if(!_private)
      return _buildPublicImage();
  }

   Future<void> _deletePhoto() async {
    await Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
    {'media': FieldValue.arrayRemove([media])}).then((_) { 
      print('Successfully deleted buddy from current user');
      Navigator.pop(context);
      }
    );
  }

  void _deletePressed() async {
   showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        title: Text('Delete Photo?'),
        contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Container(
          child: Text(
            'Do you want to delete this photo?',
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
            onPressed: () { 
              _deletePhoto();
              Navigator.pop(context);
            },
            child: Text('Yes'),
            textColor: GSColors.green,
          ),
        ],
      )
    ); 
  }

  // Build image for current user
  Widget _buildPrivateImage() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildImage(),

      // Bottom nav
      bottomNavigationBar: BottomAppBar(
        color: GSColors.darkBlue,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget> [
          Padding(padding: EdgeInsets.only(left: 300)),
          IconButton(
            icon: Icon(
              Icons.share,
              color: GSColors.babyPowder,
            ),
            onPressed: () {
              // share as a post
            },
          ),
          Padding(padding: EdgeInsets.only(left: 10)),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: GSColors.babyPowder,
              size: 26,
            ),
            onPressed: () => _deletePressed(),
            ),
          ],
        ),
      )
    );
  }

  // Build image when viewed by another user
  Widget _buildPublicImage() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildImage(),

      // Bottom nav
      bottomNavigationBar: BottomAppBar(
        color: GSColors.darkBlue,
      )
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: GSColors.darkBlue,
      iconTheme: IconThemeData(color: GSColors.purple),
      leading: IconButton(
        icon: Icon(
          Icons.keyboard_arrow_left, 
          color: Colors.white, 
          size: 32,
        ),
        onPressed: () {Navigator.pop(context);},
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(GSColors.darkCloud), 
            ),
          ),
          Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: Image.network(media).image,
              fit: BoxFit.contain
            ),
          )
        ),
      ],
    );
  }
}