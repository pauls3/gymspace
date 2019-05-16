import 'package:GymSpace/logic/group.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:GymSpace/page/group_profile_page.dart';
import 'package:GymSpace/page/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/global.dart';
import 'package:carousel_slider/carousel_slider.dart';

enum SearchType {user, group, workoutplan}

class SearchPage extends StatefulWidget {
  final SearchType searchType;
  final User currentUser;
  final List<Group> groups;
  final List<User> users;
  
  SearchPage({
    this.searchType,
    this.currentUser,
    this.groups,
    this.users,
    Key key,
  }) : super(key: key);

  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  SearchType get searchType => widget.searchType;
  List<String> get friends => widget.currentUser.buddies;
  List<Group> get groups => widget.groups;
  List<User> get users => widget.users;
  Group _currentGroup;
  bool _isEditing = true;

  TextEditingController _searchController = TextEditingController();
  List<User> usersFound = List();
  List<Group> groupsFound = List();
  List<User> allUsersFound = List();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // drawer: AppDrawer(),
      appBar: _buildAppBar(),
      // body: _isEditing ? Container() : _buildResults(),
      body: _buildResults(),
    );
  }

  void _search(String text) async {
    usersFound.clear();
    groupsFound.clear();
    allUsersFound.clear();
    
    switch (searchType) {
      case SearchType.user:
        for(User user in users) {
          String name = user.firstName + " " + user.lastName;
          if(name.toLowerCase().contains(text.toLowerCase())) 
            usersFound.add(user);
        }

        // if(allUsersFound.isNotEmpty) {
        //   usersFound = allUsersFound[0];
        // }


        //usersFound = _searchController.text.isEmpty ? List() : await DatabaseHelper.searchDBForUserByName(_searchController.text);
        break;
      case SearchType.group:
        for (Group group in groups) {
          if (group.name.toLowerCase().contains(text.toLowerCase())) {
            groupsFound.add(group);
          }
        }

        if (groupsFound.isNotEmpty) {
          _currentGroup = groupsFound[0];
        }

        break;
      default:
    }

    setState(() {
      _isEditing = false;
    });
  }

  Widget _buildAppBar() {
    return AppBar(
      // backgroundColor: GSColors.rand,
      title: Container(
        child: TextField(
          autofocus: searchType == SearchType.user ? true : false,
          controller: _searchController,
          textCapitalization: TextCapitalization.words,
          onTap: () {
            setState(() {
              _isEditing = true;
            });
          },
          onChanged: (_) {       
            setState(() {
              _isEditing = true;
              // if(searchType == SearchType.group) 
              //   _search(_searchController.text);
              
              _search(_searchController.text);
            });
          },
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(FocusNode());
            _search(_searchController.text);
          },
          style: TextStyle(
            color: Colors.white
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: searchType == SearchType.user ? 'Enter either First name or Last name' : 'Enter name of group',
            hintStyle: TextStyle(
              color: Colors.white54,
            ),
            suffixIcon: IconButton(
              color: Colors.white54,
              icon: Icon(Icons.clear),
              onPressed: () => _searchController.clear(),
            )
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    switch (searchType) {
      case SearchType.user:
        return _buildResultsUsers();
        break;
      case SearchType.group:
        return _buildResultsGroups();
        break;
      default:
        return Container();
    }
  }

  Widget _buildResultsUsers() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 40),
      child: ListView.builder(
        itemCount: usersFound.length,
        itemBuilder: (context, i)  {
          if (usersFound[i].documentID == DatabaseHelper.currentUserID) {
            return Container();
          }
          User user = usersFound[i];
          int mutualFriends = 0;
          user.buddies.forEach((potentialFriend) {
            if (friends.contains(potentialFriend)) {
              mutualFriends++;
            }
          });

          return _buildUserResult(user);
        },
      ),
    );
  }

  Widget _buildUserResult(User user) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        child: Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: ShapeDecoration(
                color: GSColors.darkBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)
                )
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: Column(
                      children: <Widget>[
                        Text(
                          '${user.firstName} ${user.lastName}',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '${user.liftingType}',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 4),
              decoration: ShapeDecoration(
                shadows: [BoxShadow(blurRadius: 2, color: GSColors.darkBlue)],
                shape: CircleBorder(
                  side: BorderSide(color: Colors.white, width: .5)
                ),
              ),
              child: CircleAvatar(
                backgroundImage: user.photoURL.isNotEmpty ? CachedNetworkImageProvider(user.photoURL) : AssetImage(Defaults.userPhoto),
                // backgroundImage: CachedNetworkImageProvider(user.photoURL.isEmpty ? Defaults.userPhoto : user.photoURL, errorListener: () => print('Failed to download')),
                radius: 50,
              ),
            ),
          ]
        ),
        onTap: () => _buildProfile(user),
      ),
    );  
  }

  Widget _buildResultsGroups() {
    return Container(
      // margin: EdgeInsets.only(top: 20),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Container(
            child: Column(
              children: _buildFoundGroups(), 
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Container(
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Explore Groups',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
           Container(
            // color: Colors.red,
            child: GridView.count(
              physics: ScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              children: _buildAllGroups(),
              childAspectRatio: 1
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFoundGroups() {
    bool foundGroup = groupsFound.isNotEmpty;
    List<Widget> groupCards = List();
    for (Group group in groupsFound) {
      groupCards.add(_buildGroupItem(group));
    }

    return <Widget>[
      foundGroup ?
        Container(
          // margin: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 30, bottom: 10),
                child: Text(
                  'Found ${groupsFound.length} groups',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              CarouselSlider(
                items: groupCards,
                enableInfiniteScroll: true,
                enlargeCenterPage: true,
                autoPlay: false,
                viewportFraction: .75,
                aspectRatio: 1.5,
                onPageChanged: (page) => setState(() {
                  _currentGroup = groupsFound[page];
                }),
              ),
              _currentGroup == null ? Container() :
              GroupInfoWidget(group: _currentGroup,),
            ],
          )
        ) : Container(),
    ];
  }

  List<Widget> _buildAllGroups() {
    List<Widget> groupItems = List();
    groups.forEach((group) { 
      groupItems.add(
        Container(
          // width: double.infinity,
          margin: EdgeInsets.all(10),
          child: _buildGroupItem(group, forAll: true),
        )
      );
    });
    
    return groupItems;
  }

  Widget _buildGroupItem(Group group, {bool forAll = false}) {
    return Container(
      width: double.maxFinite,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => GroupProfilePage(group: group,)
          ));
        },
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
                      fontSize: forAll ? 12 : 18,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      // letterSpacing: 1.2
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _buildProfile(User user) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ProfilePage.fromUser(user)
    ));
  }
}

class GroupInfoWidget extends StatefulWidget {
  final Group group;

  GroupInfoWidget({
    this.group,
    Key key}) : super(key: key);

  _GroupInfoWidgetState createState() => _GroupInfoWidgetState();
}

class _GroupInfoWidgetState extends State<GroupInfoWidget> {
  Group get group => widget.group;

  @override
  Widget build(BuildContext context) {
    bool _joined = group.members.contains(DatabaseHelper.currentUserID) || group.admin == DatabaseHelper.currentUserID;
    return Stack(
      alignment: Alignment.bottomCenter,
      fit: StackFit.loose,
      children: <Widget> [
        Container(
          padding: EdgeInsets.all(10),
          child: Container(
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: GSColors.cloud,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadows: [BoxShadow(color: Colors.black26)]
            ),
            // height: 300,
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
            // padding: EdgeInsets.only(top: 10, bottom: 20, left: 10, right: 10),
            child: Container(
              // padding: EdgeInsets.only(bottom: 20),
              // color: Colors.blue,
              child:Container(
                margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                padding: EdgeInsets.only(bottom: 16),
                // color: Colors.red,
                child: Text(
                  group.bio,
                  softWrap: true,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: GSColors.darkBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // letterSpacing: 1.2
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          alignment: Alignment.bottomLeft,
          margin: EdgeInsets.only(left: 30),
          child: FutureBuilder(
            future: DatabaseHelper.getUserSnapshot(group.admin),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircleAvatar(
                  backgroundImage: AssetImage(
                    Defaults.userPhoto,
                  )
                );
              }
              
              return CircleAvatar(
                backgroundImage: snapshot.data['photoURL'].isNotEmpty ? CachedNetworkImageProvider(snapshot.data['photoURL'])
                : AssetImage(Defaults.userPhoto),
              );
            },
          ),
          // child: CircleAvatar(
          //   backgroundImage: CachedNetworkImageProvider(
          //     group.photoURL,
          //   ),
          // ),
        ),
        Container(
          alignment: Alignment.bottomCenter,
          child: FlatButton.icon(
            color: GSColors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            icon: Icon(
              Icons.subdirectory_arrow_right,
              size: _joined ? 16 : 22,
              color: Colors.white,
            ), 
            label: Text(
              'View',
              style: TextStyle(
                color: Colors.white
              ),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => GroupProfilePage(group: group)
              ));
            },
          )
        )
      ],
    );
  }
}