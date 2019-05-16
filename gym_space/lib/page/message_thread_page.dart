import 'dart:async';
import 'dart:io';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:GymSpace/global.dart';
//import 'package:photo_view/photo_view.dart';



class MessageThreadPage extends StatelessWidget {
  final String peerId;
  final String peerAvatar;
  final String peerFirstName;
  final String peerLastName;

  MessageThreadPage({
    Key key, @required this.peerId, @required this.peerAvatar, @required this.peerFirstName, @required this.peerLastName
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: _buildAppBar(),
      body: new ChatScreen(
        peerId: peerId,
        peerAvatar: peerAvatar,
        peerFirstName: peerFirstName,
        peerLastName: peerLastName,
      ),
    );
  }

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: PageHeader(
        title: '$peerFirstName $peerLastName',
        backgroundColor: GSColors.darkBlue,
        titleColor: Colors.white,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerFirstName;
  final String peerLastName;

  ChatScreen({Key key, @required this.peerId, @required this.peerAvatar, @required this.peerFirstName, @required this.peerLastName}) : super(key: key);

  @override
  State createState() => new ChatScreenState(peerId: peerId, peerAvatar: peerAvatar, peerFirstName: peerFirstName, peerLastName: peerLastName);
}

class ChatScreenState extends State<ChatScreen> {
  ChatScreenState({Key key, @required this.peerId, @required this.peerAvatar,  @required this.peerFirstName, @required this.peerLastName});

  String peerId;
  String peerAvatar;
  String peerFirstName;
  String peerLastName;
  Future<String> futureID;
  String id;

 // PhotoViewScaleStateController _photoController = PhotoViewScaleStateController();

  List<Map<String, String>> listMessage; // var
  //var listMessage;
  String groupChatId;
  SharedPreferences prefs;

  File imageFile;
  bool isLoading;
  //bool isShowSticker;
  String imageUrl;

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    //focusNode.addListener(onFocusChange);

    groupChatId = '';

    isLoading = false;
    //isShowSticker = false;
    imageUrl = '';

    readLocal();
  }

  // void onFocusChange() {
  //   if (focusNode.hasFocus) {
  //     // Hide sticker when keyboard appear
  //     setState(() {
  //       //isShowSticker = false;
  //     });
  //   }
  // }

  readLocal() async {
    //     Future<FirebaseUser> firebaseUser =  FirebaseAuth.instance.currentUser();
    
    prefs = await SharedPreferences.getInstance();
    //id = prefs.getString('id') ?? '';

    id = await getFutureID();

    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId';
    } else {
      groupChatId = '$peerId-$id';
    }

    setState(() {});
  }

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  //Get current user ID
  Future<String> getFutureID() async{
      FirebaseUser currentuser =  await FirebaseAuth.instance.currentUser();
      return currentuser.uid;
  } 

  // void getSticker() {
  //   // Hide keyboard when sticker appear
  //   focusNode.unfocus();
  //   setState(() {
  //     isShowSticker = !isShowSticker;
  //   });
  // }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }



  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();
      //debugPrint('*******************************************************moo**');
      //debugPrint(peerAvatar);


      var documentReference = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      Firestore.instance.document(documentReference.path).setData({
        'idFrom': id,
        'idTo': peerId,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': content,
        'type': type
      });
      // var ds = await Firestore.instance.runTransaction((transaction) async {
      //   await transaction.set(
      //     documentReference,
      //     {
      //       'idFrom': id,
      //       'idTo': peerId,
      //       'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      //       'content': content,
      //       'type': type
      //     },
      //   );
      // });

      // print(ds);
      listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, Map document) { // buildMessage()
    // _photoController.
    if (document['idFrom'] == id) {
      // Right (my message)
      return Row(
        children: <Widget>[
          document['type'] == 0
          // Text
              ? Container(
            child: Text(
              document['content'],
              style: TextStyle(color: GSColors.darkBlue),
            ),
            padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
            width: 200.0,
            decoration: BoxDecoration(color: GSColors.darkCloud, borderRadius: BorderRadius.circular(8.0)),
            margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
          )
              : document['type'] == 1
          // Image
              ? Container(
            child: Material(
              // child: PhotoView(
              //   imageProvider: CachedNetworkImageProvider(
              //     document['content'],
              //   ),
              //   scaleStateController: _photoController,
              // ),
              child: CachedNetworkImage(
                placeholder: (context, string) => Container(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(GSColors.darkBlue),
                  ),
                  width: 200.0,
                  height: 200.0,
                  padding: EdgeInsets.all(70.0),
                  decoration: BoxDecoration(
                    color: GSColors.darkCloud,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                  ),
                ),
                errorWidget: (context, string, obj) => Material(
                  child: Image.asset(
                    'images/img_not_available.jpeg',
                    width: 200.0,
                    height: 200.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
                imageUrl: document['content'],
                width: 200.0,
                height: 200.0,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              clipBehavior: Clip.hardEdge,
            ),
            margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
          )
          // Sticker
              : Container(
            child: new Image.asset(
              'images/${document['content']}.gif',
              width: 100.0,
              height: 100.0,
              fit: BoxFit.cover,
            ),
            margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMessageLeft(index)
                    ? Material(
                  child: CachedNetworkImage(
                    placeholder: (context, text) => Container(
                      child: CircularProgressIndicator(
                        strokeWidth: 1.0,
                        valueColor: AlwaysStoppedAnimation<Color>(GSColors.darkBlue),
                      ),
                      width: 35.0,
                      height: 35.0,
                      padding: EdgeInsets.all(10.0),
                    ),
                    imageUrl: peerAvatar.isEmpty ? Defaults.userPhotoDB: peerAvatar,
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(18.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                )
                    : Container(width: 35.0),
                document['type'] == 0
                    ? Container(
                  child: Text(
                    document['content'],
                    style: TextStyle(color: Colors.white),
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 200.0,
                  decoration: BoxDecoration(color: GSColors.darkBlue, borderRadius: BorderRadius.circular(8.0)),
                  margin: EdgeInsets.only(left: 10.0),
                )
                    : document['type'] == 1
                    ? Container(
                  child: Material(
                    child: CachedNetworkImage(
                      placeholder: (context, text) => Container(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(GSColors.darkBlue),
                        ),
                        width: 200.0,
                        height: 200.0,
                        padding: EdgeInsets.all(70.0),
                        decoration: BoxDecoration(
                          color: GSColors.darkCloud,
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                      ),
                      errorWidget: (context, text, object) => Material(
                        child: Image.asset(
                          'images/img_not_available.jpeg',
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        clipBehavior: Clip.hardEdge,
                      ),
                      imageUrl: document['content'],
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  margin: EdgeInsets.only(left: 10.0),
                )
                    : Container(
                  child: new Image.asset(
                    'images/${document['content']}.gif',
                    width: 100.0,
                    height: 100.0,
                    fit: BoxFit.cover,
                  ),
                  margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
                ),
              ],
            ),

            // Time
            isLastMessageLeft(index)
                ? Container(
              child: Text(
                DateFormat('dd MMM kk:mm')
                    .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),
                style: TextStyle(color: GSColors.cloud, fontSize: 12.0, fontStyle: FontStyle.italic),
              ),
              margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
            )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 && listMessage != null && listMessage[index - 1]['idFrom'] == id) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 && listMessage != null && listMessage[index - 1]['idFrom'] != id) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    // if (isShowSticker) {
    //   setState(() {
    //     isShowSticker = false;
    //   });
    // } else {
      Navigator.pop(context);
    // }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              buildListMessage(),

              // Sticker
              // (isShowSticker ? buildSticker() : Container()),

              // Input content
              buildInput(),
            ],
          ),

          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
        child: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(GSColors.darkBlue)),
        ),
        color: Colors.white.withOpacity(0.8),
      )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.image),
                onPressed: getImage,
                color: GSColors.darkBlue,
              ),
            ),
            color: Colors.white,
          ),
          // Material(
          //   child: new Container(
          //     margin: new EdgeInsets.symmetric(horizontal: 1.0),
          //     child: new IconButton(
          //       icon: new Icon(Icons.face),
          //       onPressed: getSticker,
          //       color: GSColors.darkBlue,
          //     ),
          //   ),
          //   color: Colors.white,
          // ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: GSColors.darkBlue, fontSize: 15.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: GSColors.cloud),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => onSendMessage(textEditingController.text, 0),
                color: GSColors.darkBlue,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: GSColors.cloud, width: 0.5)), color: Colors.white),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(GSColors.darkBlue)))
          : StreamBuilder(
        stream: Firestore.instance
            .collection('messages')
            .document(groupChatId)
            .collection(groupChatId)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(GSColors.darkBlue)));
          } else {
            //List<DocumentSnapshot> is not a subtype of type List<Map<String, String>>
            //debugPrint('oink');
            //listMessage = snapshot.data.documents;
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => buildItem(index, snapshot.data.documents[index].data),
              itemCount: snapshot.data.documents.length,
              reverse: true,
              controller: listScrollController,
            );
          }
        },
      ),
    );
  }
}