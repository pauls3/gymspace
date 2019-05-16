import 'dart:async';

import 'package:GymSpace/widgets/image_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:GymSpace/global.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MediaTab extends StatefulWidget {
  MediaTab({Key key}) : super(key: key);
  _MediaTabState createState() => _MediaTabState();
}

class _MediaTabState extends State<MediaTab> {
  String mediaUrl, profileImageUrl;
  List<String> media = [];
  Future<List<String>> _listFutureUser = DatabaseHelper.getUserMedia(DatabaseHelper.currentUserID);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _buildMediaLabel(),
        _buildMediaList(context),
        _buildButton(),
      ],
    );
  }

  Widget _buildMediaLabel() {
    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: <Widget>[ 
          Expanded(
            flex: 1,
            child: Container(),
          ),
          Expanded(
            flex: 1,
            child: Container(
              height: 40,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  "Photos",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                )),
                decoration: ShapeDecoration(
                  color: GSColors.darkBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      topRight: Radius.circular(20)
                    )
                  )
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    return StreamBuilder(
      stream: _listFutureUser.asStream(),
      builder: (context, snapshot) {
        if(!snapshot.hasData)
          return Container();

        return Column(
        children: <Widget>[
          //DIY floating action button!
          Container(
            alignment: Alignment.bottomRight,
              child: Container(
                margin: EdgeInsets.only(top: 15, right: 50),
                height: 40,
                width: 40,
                decoration: ShapeDecoration(
                  color: GSColors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
                child: IconButton(
                  icon: Icon(FontAwesomeIcons.plus),
                  iconSize: 12,
                  color: Colors.white,
                  onPressed: () => setState(() {
                    getMediaImage();
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaList(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 50, left: 10, right: 10, bottom: 10),
      child: StreamBuilder(
        stream: _listFutureUser.asStream(),
        builder: (context, snapshot) {
          if(!snapshot.hasData)
            return Container();

          media = snapshot.data;
          return GridView.builder(
            padding: EdgeInsets.all(15),
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
    );
  }

  Widget _buildMediaItem(String media) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute<void> (
          builder: (BuildContext context) {
            return ImageWidget(media, context, true);
          },
        )
      ),
      child: Card(
        elevation: 6,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(media),
              fit: BoxFit.cover
            ),
          ),
        ),
      ),
    );
  }

  // *****************************************************************************
  // ***************************** UPLOAD A NORMAL PHOTO *************************
  Future<String> getMediaImage() async {
    var tempImage = await ImagePicker.pickImage(source: ImageSource.gallery);
    
    if(tempImage != null) {   
      setState(() {
        uploadMediaFile(tempImage);
        return tempImage.uri.toString();
      }); 
    }

    setState(() {
      return tempImage.uri.toString();
    });

  }

  Future uploadMediaFile(File mediaImage) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);

    StorageUploadTask uploadTask = reference.putFile(mediaImage);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;

    await storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      mediaUrl = downloadUrl;
    }, 

    onError: (err) {
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
        
    await DatabaseHelper.getUserSnapshot(DatabaseHelper.currentUserID).then(
      (ds) => ds.reference.updateData({'media': FieldValue.arrayUnion([mediaUrl])})
    );
  }
}
