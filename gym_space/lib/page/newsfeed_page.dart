import 'dart:async';
import 'dart:io';
import 'package:GymSpace/logic/group.dart';
import 'package:GymSpace/logic/post.dart';
import 'package:GymSpace/widgets/post_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/global.dart';
import 'package:GymSpace/widgets/app_drawer.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:photo_view/photo_view.dart';
import 'package:GymSpace/page/notification_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NewsfeedPage extends StatefulWidget {
  final Group forGroup;

  NewsfeedPage({this.forGroup});

  @override
  _NewsfeedPageState createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  bool _addedPhoto = false;
  List<Widget> _fetchedPosts = List();
  bool _fetchingPosts = false;
  bool _isCreatingPost = false;
  String _uploadBody = '';
  File _uploadImage;
  final localNotify = FlutterLocalNotificationsPlugin();
  Group get group => widget.forGroup;

  @override
  void initState() {
    super.initState();
    final settingsAndriod = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settingsIOS = IOSInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) =>
        onSelectNotification(payload));
    localNotify.initialize(InitializationSettings(settingsAndriod, settingsIOS),
      onSelectNotification: onSelectNotification);
    _fetchPosts();
  }

  Future onSelectNotification(String payload) async  {
    Navigator.pop(context);
    print("==============OnSelect WAS CALLED===========");
    await Navigator.push(context, new MaterialPageRoute(builder: (context) => NotificationPage()));
  }

  String get currentUserID => DatabaseHelper.currentUserID;

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: Container(
        color: GSColors.darkBlue,
        child: PageHeader(
          title: group == null ? "Newsfeed" : 'Group Newsfeed',
          backgroundColor: GSColors.darkBlue,
          showDrawer: group == null,
          titleColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return LiquidPullToRefresh(
      onRefresh: _fetchPosts,
      color: GSColors.darkBlue,
      backgroundColor: Colors.white,
      child: _fetchingPosts ? ListView(
        children: <Widget>[],
      )
      : ListView(
          cacheExtent: 99999,
          padding: EdgeInsets.only(top: 20),
          // shrinkWrap: true,
          children: _fetchedPosts,
          // itemExtent: 400,
        )
    );
  }

  Future<void> _fetchPosts() async {
    setState(() {
      print('Fetching posts...');
      _fetchingPosts = true;
    });

    List<String> collectedPosts = group == null ? await DatabaseHelper.fetchPosts() : await DatabaseHelper.fetchGroupPosts(group.documentID);
    
    print('Fetched ${collectedPosts.length} posts');
    if (collectedPosts.isNotEmpty) 
      _fetchedPosts.clear();

    DocumentSnapshot userDS = await DatabaseHelper.getUserSnapshot(DatabaseHelper.currentUserID);
    List<String> joinedGroups = userDS.data['joinedGroups'].cast<String>();
    // build each post
    collectedPosts.sort((String a, String b) => int.parse(a).compareTo(int.parse(b)));
    for (String postID in collectedPosts.reversed) { // build the post 
      _fetchedPosts.add(_buildPost(postID, joinedGroups));
    }
    
    setState(() {
        _fetchingPosts = false;
      });
  }

  void _addPressed() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildPostContainer()
    );
  }

  Widget _buildPost(String postID, List<String> joinedGroups) {
    return Container(
      child: StreamBuilder(
        stream: DatabaseHelper.getPostStream(postID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } 
          
          if (!snapshot.hasData) 
            return Container();

          if (snapshot.data.data == null) {
            return Container();
          }

          Post post = Post.jsonToPost(snapshot.data.data);
          post.documentID = snapshot.data.documentID;

          if (post.fromGroup.isNotEmpty && !joinedGroups.contains(post.fromGroup)) {
            return Container();
          }
          
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: InkWell(
              onLongPress: () => _postLongPressed(post),
              child: PostWidget(post: post,),
            ),
          );
        },
      ),
    );
  }

  void _postLongPressed(Post post) {
    if (post.fromUser != currentUserID) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (bulder) {
        return Container(
          child: FlatButton.icon(
            icon: Icon(Icons.delete),
            label: Text('Delete Post'),
            textColor: GSColors.red,
            onPressed: () => _deletePressed(post),
          )
        );
      } 
    );
  }

  void _deletePressed(Post post) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text('Are you sure?'),
              FlatButton.icon(
                textColor: GSColors.red,
                icon: Icon(Icons.cancel),
                label: Text('No'),
                onPressed: () {Navigator.pop(context);},
              ),
              FlatButton.icon(
                textColor: GSColors.green,
                icon: Icon(Icons.check),
                label: Text('Yes'),
                onPressed: () => _deletePost(post),    
              )        
            ],
          ),
        );
      }
    );
  }

  Future<void> _deletePost(Post post) async {
    Navigator.pop(context);

    await Firestore.instance.collection('posts').document(post.documentID).delete()
      .then((_) async {
        _fetchPosts();
        setState(() {
          Fluttertoast.showToast(msg: 'Deleted Post');
        });
      });
  }

  Widget _buildPostContainer() {
    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: Duration(milliseconds: 1),
      child: Container(
        margin: EdgeInsets.only(left: 10, right: 40, bottom: 10),
        child: TextField(
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          maxLines: null,
          onChanged: (text) => _uploadBody = text,
          decoration: InputDecoration(
            labelText: 'What do you want to share?',
            icon: Hero(
              tag: 'postImage',
              child: IconButton(
                onPressed: _uploadImage == null ? _addPhoto : _uploadImagePressed,
                icon: _uploadImage != null ? Image.file(_uploadImage,height: 100, width: 100,) 
                : Icon(Icons.add_photo_alternate, color: GSColors.yellow,),
              ),
            ),
            suffixIcon: Container(
              child: FlatButton(
                child: Text(
                  'Post',
                  style: TextStyle(
                    fontSize: 18,
                    color: GSColors.lightBlue
                  ),
                ),
                onPressed: _uploadPost,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadPost() async {
    if (_uploadBody.isEmpty && _uploadImage == null) {
      Navigator.pop(context);
      return;
    }

    Post newPost = Post(
      body: _uploadBody,
      fromUser: currentUserID,
      fromGroup: group == null ? '' : group.documentID,
    );

    // upload image to db
    if (_uploadImage != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
      StorageUploadTask uploadTask = reference.putFile(_uploadImage);
      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;

      await storageTaskSnapshot.ref.getDownloadURL().then((downloadURL) {
        newPost.mediaURL = downloadURL;
        print('photo url: $downloadURL');
      }).catchError((e) => Fluttertoast.showToast(msg: 'This file is not an image'));
    }

    // now upload post to db
    await Firestore.instance.collection('posts').document(DateTime.now().millisecondsSinceEpoch.toString()).setData(newPost.toJSON()).then((_) async {
      _fetchPosts();
      setState(() {
        _uploadBody = '';
        _uploadImage = null;
        Navigator.pop(context);
      });
    });
  }

  Future<void> _addPhoto() async {
    _uploadImage = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (_uploadImage == null) {
      _addedPhoto = false;
      return;
    }

    setState(() => _addedPhoto = true);
  }

  void _uploadImagePressed() {
    showMenu(
      context: context, 
      items: [
        PopupMenuItem(
          child: Container(
            child: FlatButton.icon(
              textColor: GSColors.red,
              icon: Icon(Icons.remove, color: GSColors.red,),
              label: Text('Remove'),
              onPressed: _removeUploadImage,
            ),
          ),
        ),
        PopupMenuItem(
          child: Container(
            child: FlatButton.icon(
              textColor: GSColors.lightBlue,
              icon: Icon(Icons.add_photo_alternate, color: GSColors.lightBlue,),
              label: Text('Choose different image'),
              onPressed: () => _addPhoto().then((_) => Navigator.pop(context)),
            ),
          ),
        ),
        PopupMenuItem(
          child: Container(
            child: FlatButton.icon(
              textColor: GSColors.green,
              icon: Icon(FontAwesomeIcons.image, color: GSColors.green),
              label: Text('View'),
              onPressed: _viewImage,
            ),
          ),
        )
      ],
      position: RelativeRect.fromLTRB(0, double.infinity, 0, 0)
      
    );
  }

  void _viewImage() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => HeroPhotoView(imageProvider: FileImage(_uploadImage))
    )).then((_) => Navigator.pop(context));
  }

  void _removeUploadImage() {
    setState(() {
      print('removing photo');
      _addedPhoto = false;
      _uploadImage = null;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (group != null) {
      return Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: GSColors.darkBlue,
        body: _buildBody(),
        floatingActionButton: FlatButton.icon(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: GSColors.green,
          label: Text('Add Post'),
          textColor: Colors.white,
          icon: Icon(Icons.add_circle,),
          onPressed: _addPressed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(startPage: 0,),
      backgroundColor: GSColors.darkBlue,
      body: _buildBody(),
      floatingActionButton: FlatButton.icon(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: GSColors.green,
        label: Text('Add Post'),
        textColor: Colors.white,
        icon: Icon(Icons.add_circle,),
        onPressed: _addPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}

class HeroPhotoView extends StatelessWidget {
  const HeroPhotoView({
    @required this.imageProvider,
    Key key}) : super(key: key);

  final ImageProvider imageProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: PhotoView(
        initialScale: .1,
        imageProvider: imageProvider,
        heroTag: 'postImage',
      )
    );
  }
}