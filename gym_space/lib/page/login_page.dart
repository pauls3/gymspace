import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/logic/auth.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:GymSpace/misc/bubblecontroller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:GymSpace/page/me_page.dart';
import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/global.dart';


class LoginPage extends StatefulWidget {
  LoginPage({@required this.auth, @required this.authStatus});
  AuthStatus authStatus;
  final BaseAuth auth;
  final VoidCallback onLoggedIn = null;
  @override
  LoginPageState createState () => new LoginPageState();
}

enum FormType {
  login,
  register
}
class LoginPageState extends State<LoginPage>{
  final FocusNode myFocusNodeEmail = FocusNode();
  final formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final FirebaseMessaging _messaging = FirebaseMessaging();

  // User info
  String _email;
  String _password;
  String _firstName;
  String _lastName;
  FormType _formType = FormType.login;

  PageController _pageController;
  GlobalKey<FormFieldState> _passwordKey = GlobalKey<FormFieldState>();

  Color left = Colors.black;
  Color right = Colors.white;

  
 

  bool validateAndSave() {
    final form = formKey.currentState;
    if(form.validate()){
      form.save();
      return true;
    }
    return false;
  }

  // Checks if User is valid from Firebase authentication 
  void validateAndSubmit() async {
    if(validateAndSave()) {
      try {
        if(_formType == FormType.login) {
           DatabaseHelper.currentUserID = await widget.auth.signInWithEmailAndPassword(_email, _password);   
          print('Signed in: ' +  DatabaseHelper.currentUserID);
          widget.authStatus = AuthStatus.loggedIn;
        }
        else {
           DatabaseHelper.currentUserID = await widget.auth.createUserWithEmailAndPassword(_email, _password);
          _addUserToDB( DatabaseHelper.currentUserID);
          print('Registered User: ' +  DatabaseHelper.currentUserID);
        }
        // widget.onLoggedIn();
        widget.authStatus = AuthStatus.loggedIn;
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(
          builder: (BuildContext context) => MePage()
        ));
      }
      catch (e) {
        print('Error: $e');
      }
    }
  }

void _addUserToDB(String userID) async {  
  await Firestore.instance.collection('users').document(userID).setData(
    User(
      firstName: _firstName,
      lastName: _lastName,
      email: _email,
      fcmToken: await _messaging.getToken()
    ).toJSON());
}

void moveToRegister() {
    formKey.currentState.reset();
    setState(() {
      _formType = FormType.register;
    });
  }

  // Move buttons to show 'Login'
  void moveToLogin() {
    formKey.currentState.reset();
    setState(() {
      _formType = FormType.login;
    });
  }
  
  // Existing Button
  void _existing() {
    moveToLogin();
    _pageController.animateToPage(0,
      duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  // New User Button
  void _newUser() {
    moveToRegister();
    _pageController?.animateToPage(1,
      duration: Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  @override
  void initState(){
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context){
    return new Scaffold(
      key: _scaffoldKey,
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (overscroll){
          overscroll.disallowGlow();
        },
        child: SingleChildScrollView(
          child: Container(
            width:MediaQuery.of(context).size.width,
            height:MediaQuery.of(context).size.height >= 775.0 
              ? MediaQuery.of(context).size.height : 775.0,
            decoration: new BoxDecoration(
              image: DecorationImage(
                colorFilter: ColorFilter.mode(GSColors.darkBlue, BlendMode.overlay),
                fit: BoxFit.fill,
                image: AssetImage(
                  Defaults.groupPhoto,
                ),
              )
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Column (
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Padding(
                    padding:EdgeInsets.only(top: 75.0),
                    child: new Image (
                      width: 250.0,
                      height: 191.0,
                      fit:BoxFit.fill, 
                      image: new AssetImage("lib/assets/gymspacelogo.png")
                    ),
                  ),
                  Padding (
                    padding:  EdgeInsets.only(top: 20.0),
                    child: _buildSlidingMenuBar(context),
                  ),
                  Expanded(
                    flex: 2,
                    child: new Form(
                      key: formKey,
                      child: PageView(
                        controller:_pageController,
                        onPageChanged: (i) {
                          if (i == 0){
                            setState((){
                              right = Colors.white;
                              left = Colors.black;
                            });
                          }
                          else if (i == 1){
                            setState((){
                              right = Colors.black;
                              left = Colors.white;
                            });
                          }
                        },
                        children: <Widget>[
                          new ConstrainedBox(
                            constraints: const BoxConstraints.expand(),
                            child: _buildLogin(context),
                          ),
                            new ConstrainedBox(
                            constraints: const BoxConstraints.expand(),
                            child: _buildNewUser(context),
                          ),
                        ],
                      ),
                    )
                  )
                ],
              )
            )
          )
        )
      ),
    );
  }

  // Builds Sliding Bar
  Widget _buildSlidingMenuBar (BuildContext context){
    return Container (
      width: 300.0,
      height: 50.0,
      // decoration:BoxDecoration(
      //   color: GSColors.blue,
      //   borderRadius: BorderRadius.all(Radius.circular(25.0)),
      // ),
      child:CustomPaint(
        painter: TabIndicationPainter(pageController: _pageController),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _existing,
                child: Text (
                  "Existing",
                  style:TextStyle(
                    color: left,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FlatButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: _newUser,
                child: Text(
                  "New User",
                  style: TextStyle(
                    color: right,
                    fontSize: 16.0
                  ),
                )
              )
            )
          ],
        ),
      )
    );
  }

 @override
 void dispose() {
   _pageController?.dispose();
   super.dispose();
 }

// Builds log
Widget _buildLogin(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 23.0),
      child: Column(
        children: <Widget>[
          Stack(
            alignment: Alignment.topCenter,
            overflow: Overflow.visible,
            children: <Widget>[
              Card(
                elevation: 2.0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(
                  width: 300.0,
                  height: 190.0,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            top: 5.0, bottom: 5.0, left: 25.0, right: 25.0),
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value == null ? 'Error: Email is empty' : null,
                          onSaved: (value) => _email = value,
                          style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.envelope,
                              color: Colors.black,
                              size: 22.0,
                            ),
                            hintText: "Email Address",
                            hintStyle: TextStyle(fontSize: 17.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 5.0, bottom: 5.0, left: 25.0, right: 25.0),
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          validator: (value) => value == null ? 'Error: Password is empty' : null,
                          onSaved: (value) => _password = value,
                          style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.lock,
                              size: 22.0,
                              color: Colors.black,
                            ),
                            hintText: "Password",
                            hintStyle: TextStyle( fontSize: 17.0),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: FlatButton(
                          onPressed: _forgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: GSColors.darkBlue.withAlpha(100),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 170.0),
                decoration: new BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  color: GSColors.darkBlue,
                  // border: Border.all(color: Colors.white, width: .5),
                ),
                child: MaterialButton(
                  highlightColor: Colors.transparent,
                  splashColor: GSColors.darkCloud,
                  //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 42.0),
                    child: Text(
                      "LOGIN",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25.0),
                    ),
                  ),
                  onPressed: () {
                    validateAndSubmit();
                  }
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _forgotPassword() {
    // FirebaseAuth.instance.sendPasswordResetEmail();
    String email = '';
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          margin: MediaQuery.of(context).viewInsets,
          child: ListTile(
            title: TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email address',
              ),
              onChanged: (text) => email = text,
            ),
            trailing: IconButton(
              icon: Icon(Icons.send), 
              color: GSColors.lightBlue,
              onPressed: () {
                if (email.isEmpty) {
                  return;
                }

                // FirebaseAuth.instance.fe

                FirebaseAuth.instance.sendPasswordResetEmail(email: email)
                  .catchError((e) {
                    Fluttertoast.showToast(msg: '$e');
                  })
                  .then((_) {
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'Check your inbox!');
                  });
              },
            ),
          ),
        );
      }
    );
  }

  // Builds Sign Up Page <==>  Page View #2
  Widget _buildNewUser(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 23.0),
      child: Column(
        children: <Widget>[
          Stack(
            alignment: Alignment.topCenter,
            overflow: Overflow.visible,
            children: <Widget>[
              Card(
                elevation: 2.0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(
                  width: 300.0,
                  height: 360.0,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            top: 2.0, bottom: 2.0, left: 25.0, right: 25.0),
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => value == null ? 'Error: First Name is empty' : null,
                          onSaved: (value) => _firstName = value,
                          style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.user,
                              color: Colors.black,
                            ),
                            hintText: "First Name",
                            hintStyle: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                       Padding(
                        padding: EdgeInsets.only(
                            top: 2.0, bottom: 2.0, left: 65.0, right: 25.0),
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => value == null ? 'Error: Last Name is empty' : null,
                          onSaved: (value) => _lastName = value,
                          style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Last Name",
                            hintStyle: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 2.0, bottom: 2.0, left: 25.0, right: 25.0),
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value == null ? 'Error: Email is empty' : null,
                          onSaved: (value) => _email = value,
                          style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.envelope,
                              color: Colors.black,
                            ),
                            hintText: "Email Address",
                            hintStyle: TextStyle( fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 2.0, bottom: 2.0, left: 25.0, right: 25.0),
                        child: TextFormField(
                          key: _passwordKey,
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          validator: (value) => value == null ? 'Error: Password is empty' : null,
                          onFieldSubmitted: (value) => _password = value,
                          onSaved: (value) => _password = value,
                          style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black
                              ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.lock,
                              color: Colors.black,
                            ),
                            hintText: "Password",
                            hintStyle: TextStyle( fontSize: 16.0),
                          ),
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 2.0, bottom: 2.0, left: 25.0, right: 25.0),
                          child: TextFormField(
                          keyboardType: TextInputType.text,
                          obscureText: true,
                          validator: (value) => value != _passwordKey.currentState.value ? 'Error: Password is not matching' : null,
                          onSaved: (value) => _password = value,
                          style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.lock,
                              color: Colors.black,
                            ),
                            hintText: "Confirm Password",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 340.0),
                decoration: new BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  color: GSColors.darkBlue,
                ),
                child: MaterialButton(
                  highlightColor: Colors.transparent,
                  //shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 42.0),
                    child: Text(
                      "SIGN UP",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25.0),
                    ),
                  ),
                  onPressed: (){
                    validateAndSubmit();
                  }
                )
              ),
            ],
          ),
        ],
      ),
    );
  }
}