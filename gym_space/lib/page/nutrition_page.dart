import 'package:GymSpace/logic/user.dart';
import 'package:GymSpace/widgets/app_drawer.dart';
import 'package:GymSpace/widgets/nutrition_widget.dart';
import 'package:GymSpace/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:GymSpace/global.dart';
import 'package:GymSpace/misc/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:GymSpace/page/notification_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
class NutritionPage extends StatefulWidget {
  bool popIt;
  NutritionPage(
    {Key key}) : super(key: key);

  NutritionPage.fromMe(this.popIt, {Key key}) : super(key: key);

  _NutritionPage createState() => _NutritionPage();
}

class _NutritionPage extends State<NutritionPage> {
  String _dietKey = DateTime.now().toString().substring(0,10);
  //DateTime _constantDay = DateTime.now(); // does not change
  DateTime _week = DateTime.now();
  DateTime now = DateTime.now();
  DateTime _mon = DateTime.now();
  DateTime _tue = DateTime.now();
  DateTime _wed = DateTime.now();
  DateTime _thur = DateTime.now();
  DateTime _fri = DateTime.now();
  DateTime _sat = DateTime.now();
  DateTime _sun = DateTime.now();
  String _monKey, _tueKey, _wedKey, _thurKey, _friKey, _satKey, _sunKey;
  bool _selectDay = true;
  bool popIt = false;
  int _highlightDay;
  external int get weekday;
  final localNotify = FlutterLocalNotificationsPlugin();
  // Local Notification Plugin 
  @override
  void initState() {
    super.initState();

    if(widget.popIt == true) 
      popIt = true;

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

  Widget build(BuildContext context) {
    _highlightDay = now.weekday;
    return SafeArea(
      child: popIt == false ? Scaffold(
      drawer: AppDrawer(startPage: 3,),
      backgroundColor: GSColors.darkBlue,
      floatingActionButton: FloatingActionButton(
        child: Icon(
          FontAwesomeIcons.plus,
          size: 14,
          color: Colors.white
        ),
        backgroundColor: GSColors.purple,
        onPressed: () => NutritionWidget().updateNutritionInfo(context, _dietKey), 
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: _buildAppBar(),
      body: _buildBody(context),
      ) // User calling themself not thru app drawer, create a back arrow
      : Scaffold(
        //drawer: AppDrawer(startPage: 3,),
        backgroundColor: GSColors.darkBlue,
        floatingActionButton: FloatingActionButton(
          child: Icon(
            FontAwesomeIcons.plus,
            size: 14,
            color: Colors.white
          ),
          backgroundColor: GSColors.purple,
          onPressed: () => NutritionWidget().updateNutritionInfo(context, _dietKey), 
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        appBar: _buildAppBar(),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: PageHeader(
        title: 'Nutrition', 
        backgroundColor: Colors.white, 
        showDrawer: true,
        titleColor: GSColors.darkBlue,
      )
    );  
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      child: ListView(
        children: <Widget>[
          _buildWeeklyLabel(),
          _buildWeeklyBuilder(),
          _buildNutritionLabel(),
          _buildNutritionInfo(context),
        ],
      ),
    );
  }

  Widget _buildWeeklyLabel() {
    _setWeek();
    return Container(
      margin: EdgeInsets.only(top: 15),
      height: 40,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Container(),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.centerRight,
              child: Text(
                // Get month of latest day in the week
                DateFormat('MMMM').format(_sat),
                style: TextStyle(
                  color: GSColors.darkBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  )
                 )
              )
            )
          ),
          Container(
            color: Colors.white,
            child: IconButton(
              icon: Icon(FontAwesomeIcons.chevronRight),
              iconSize: 12,
              onPressed: () {
                // Possibly open up monthly nutrition, let user look at complete past 
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBuilder() {
    return Container(
      height: 80, 
      margin: EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 12),
              itemCount: 1,
              itemBuilder: (BuildContext context, int i) {

              return StreamBuilder(
                stream: DatabaseHelper.getUserStreamSnapshot(DatabaseHelper.currentUserID),
                builder: (context, snapshot) {
                  if(!snapshot.hasData)
                    return Container();

                    User user = User.jsonToUser(snapshot.data.data);
                    return _buildWeeklyProgress(user, snapshot);
                  }
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(User user, AsyncSnapshot<dynamic> snapshot) {
    return Container(
      child: Row(
        children: <Widget>[
          _buildWeeklyCircle(user, snapshot, _sunKey, "S", 7, _sun),
          _buildWeeklyCircle(user, snapshot, _monKey, "M", 1, _mon),
          _buildWeeklyCircle(user, snapshot, _tueKey, "T", 2, _tue),
          _buildWeeklyCircle(user, snapshot, _wedKey, "W", 3, _wed),
          _buildWeeklyCircle(user, snapshot, _thurKey, "T", 4, _thur),
          _buildWeeklyCircle(user, snapshot, _friKey, "F", 5, _fri),
          _buildWeeklyCircle(user, snapshot, _satKey, "S", 6, _sat),
        ],
      )
    );
  }

  void _setWeek() {
    // Get Sunday as a base
    while(_sun.weekday != 7)  // if not currently sunday
      _sun = _sun.subtract(Duration(days: 1));

    _week = _sun;
    // Sets this Sunday as base, do not go before this
    _mon = _week;
    _tue = _week;
    _wed = _week;
    _thur = _week;
    _fri = _week;
    _sat = _week;

    // Set each day of the week
    while(_mon.weekday % 7 != 1)
      _mon = _mon.add(Duration(days: 1));

    while(_tue.weekday % 7 != 2)
      _tue = _tue.add(Duration(days: 1));

    while(_wed.weekday % 7 != 3)
      _wed = _wed.add(Duration(days: 1));

    while(_thur.weekday % 7 != 4)
      _thur = _thur.add(Duration(days: 1));

    while(_fri.weekday % 7 != 5)
      _fri = _fri.add(Duration(days: 1));

    while(_sat.weekday % 7 != 6)
      _sat = _sat.add(Duration(days: 1));
  }

  void _weeklyNavigator(DateTime _chosenDay, int day) {
    // Cannot choose day after today
    _checkDay(_chosenDay);
  
    if(_selectDay) {
      // If day selected is after chosen day, increment days
      _highlightDay = day;
      if(now.isAfter(_chosenDay)) {
        while(now.weekday != day) 
          setState(() => now = now.subtract(Duration(days: 1)));
      } 
      // If day is selected before chosen day, decrement days
      else if(now.isBefore(_chosenDay)) {
        _highlightDay = day;
        while(now.weekday != day) 
          setState(() => now = now.add(Duration(days: 1)));
      }
    }
  }

  void _checkDay(DateTime _chosenDay) {
    DateTime _constantDay = DateTime.now();
    if(_chosenDay.isAfter(_constantDay) || _chosenDay == _constantDay) 
      setState(() => _selectDay = false);
    else
      setState(() => _selectDay = true);
  }

  Widget _buildWeeklyCircle(User user, AsyncSnapshot<dynamic> snapshot, 
                              String _dailyKey, String dayLetter, int dayNum, DateTime thisDay) {

    _dailyKey = thisDay.toString().substring(0,10);

    if(user.diet[_dailyKey] != null && snapshot.data['caloricGoal'] > 0 && user.diet[_dailyKey][3] <= snapshot.data['caloricGoal']) {
      return Container(
        margin: EdgeInsets.only(right: 12),
        child: InkWell(
          child: CircularPercentIndicator(
            animation: true,
            radius: 45.0,
            lineWidth: 5.0,
            percent: snapshot.data['diet'][_dailyKey][3] / snapshot.data['caloricGoal'],
            progressColor: GSColors.lightBlue,
            backgroundColor: GSColors.darkCloud,
            circularStrokeCap: CircularStrokeCap.round,

            // Highlight current day
            header: _highlightDay == dayNum ? Container(
              margin: EdgeInsets.only(bottom: 3),
              decoration: ShapeDecoration(
                color: GSColors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                dayLetter,
                style: TextStyle(color: GSColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 14.0),
              ),  
            )) 
            : Container(
                margin: EdgeInsets.only(bottom: 3),
                child: Text(
                  dayLetter,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
              )),  

            center: 
              Text(
                '${user.diet[_dailyKey][3]}',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
            )
          ),
          onTap: () => setState(() {
            _weeklyNavigator(thisDay, dayNum);
          }),
        )
      );
    }

    else if(user.diet[_dailyKey] != null && snapshot.data['caloricGoal'] > 0 && user.diet[_dailyKey][3] > snapshot.data['caloricGoal']) {
      return Container(
        margin: EdgeInsets.only(right: 12),
        child: InkWell(
          child: CircularPercentIndicator(
            radius: 45.0,
            lineWidth: 4.5,  
            percent: 1.0,
            progressColor: GSColors.green,
            backgroundColor: GSColors.darkCloud,

            header: _highlightDay == dayNum ? Container(
              margin: EdgeInsets.only(bottom: 3),
              decoration: ShapeDecoration(
                color: GSColors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
               child: Container(
                margin: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                dayLetter,
                style: TextStyle(color: GSColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 14.0),
              ),  
            )) 
            : Container(
                margin: EdgeInsets.only(bottom: 3),
                child: Text(
                  dayLetter,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
              )),  

            center: Text ( 
              '${user.diet[_dailyKey][3]}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.0),
            ),
          ),
          onTap: () => setState(() {
            _weeklyNavigator(thisDay, dayNum);
          }),
        ), 
      );
    }

    else if(user.diet[_dailyKey] != null && snapshot.data['caloricGoal'] == 0) {
      return Container(
        margin: EdgeInsets.only(right: 12),
        child: InkWell(
          child: CircularPercentIndicator(
            radius: 45.0,
            lineWidth: 4.0,  
            percent: 0.0,
            progressColor: GSColors.darkCloud,
            backgroundColor: GSColors.darkCloud,
            header: _highlightDay == dayNum ? Container(
              margin: EdgeInsets.only(bottom: 3),
              decoration: ShapeDecoration(
                color: GSColors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
               child: Container(
                margin: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                dayLetter,
                style: TextStyle(color: GSColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 14.0),
              ),  
            )) 
            : Container(
                margin: EdgeInsets.only(bottom: 3),
                child: Text(
                  dayLetter,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
              )),  

            center: Text ( 
              '${user.diet[_dailyKey][3]}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
            ),
          ),
          onTap: () => setState(() {
            _weeklyNavigator(thisDay, dayNum);
          }),
        ),
      );
    }

    // CASE WITH 0%
    else {
      return Container(
        margin: EdgeInsets.only(right: 12),
        child: InkWell(
          child: CircularPercentIndicator(
            radius: 45.0,
            lineWidth: 4.0,  
            percent: 0,
            progressColor: GSColors.darkCloud,
            backgroundColor: GSColors.darkCloud,
            header: _highlightDay == dayNum ? Container(
              margin: EdgeInsets.only(bottom: 3),
              decoration: ShapeDecoration(
                color: GSColors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
               child: Container(
                margin: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                dayLetter,
                style: TextStyle(color: GSColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 14.0),
              ),  
            )) 
            : Container(
                margin: EdgeInsets.only(bottom: 3),
                child: Text(
                  dayLetter,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
              )),  

            center: Text(
                '0',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
          ),
          onTap: () => setState(() {
            _weeklyNavigator(thisDay, dayNum);
          }),
        ), 
      );
    }
  }

  Widget _buildNutritionLabel() {
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Row(
        children: <Widget>[ 
          Expanded(
            flex: 3,
              child: Container(
                height: 40,
                margin: EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                child: Text(
                  //day.weekday.toString(),
                  // Get day of current nutrition thing
                  DateFormat('EEEE, MMM dd, y').format(now),
                  style: TextStyle(
                    color: GSColors.darkBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2
                  ),
                ),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(20),
                      topRight: Radius.circular(20)
                    )
                  )
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

  void _checkDailyMacrosExist() async{
  List<int> newMacros = new List(5);

  DocumentSnapshot macroDoc = await Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).get();//await Firestore.instance.collection('user').document(DatabaseHelper.currentUserID);
  var macroFromDB = macroDoc.data['diet'];
 
  if(macroFromDB[_dietKey] == null)
  {
    newMacros[0] = 0;   //protein
    newMacros[1] = 0;   //carbs
    newMacros[2] = 0;   //fats
    newMacros[3] = 0;   //current calories
    newMacros[4] = 0;   //caloric goal

    macroFromDB[_dietKey] = newMacros;

    Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
              {'diet': macroFromDB});
  }
}

  Widget _buildNutritionInfo(BuildContext context) {
  _checkDailyMacrosExist();
    return Container(
      //onTap: () => print("Open nutrition info"),
      margin: EdgeInsets.only(top: 15),
      padding: EdgeInsets.only(bottom: 5),
      child: Container(
        child: Column(
          children: <Widget>[
            Container(
              child: Container(
                child: StreamBuilder(
                  stream: DatabaseHelper.getUserStreamSnapshot(DatabaseHelper.currentUserID),
                  builder: (context, snapshot){ 
                    if(!snapshot.hasData)
                      return Container();
                  
                    User user = User.jsonToUser(snapshot.data.data);

                    // Set _dietKey to the circle user pressed
                    _dietKey = now.toString().substring(0,10);       

                    //if(user.diet[_dietKey] != null && snapshot.data['diet'][_dietKey][4] > 0)
                    if(user.diet[_dietKey] != null && snapshot.data['caloricGoal'] > 0 && user.diet[_dietKey][3] <= snapshot.data['caloricGoal'])
                    {
                      return CircularPercentIndicator(
                        animation: true,
                        radius: 140.0,
                        lineWidth: 15,
                        percent: snapshot.data['diet'][_dietKey][3] / snapshot.data['caloricGoal'],
                        progressColor: GSColors.lightBlue,
                        backgroundColor: GSColors.darkCloud,
                        circularStrokeCap: CircularStrokeCap.round,
                        footer:   
                          Container(
                            margin: EdgeInsets.only(top: 20),
                            child: Text(
                              "Calories Consumed",
                              style: TextStyle(color: Colors.white, fontSize: 20.0),
                            ),
                          ),
                        center: 
                          Text(
                            '${user.diet[_dietKey][3].toString()}',
                            style: TextStyle(color: Colors.white, fontSize: 30.0),

                        ),
                      );
                    }
                    
                    else if(user.diet[_dietKey] != null && snapshot.data['caloricGoal'] > 0 && user.diet[_dietKey][3] > snapshot.data['caloricGoal'])
                    {
                      return CircularPercentIndicator(
                        radius: 140.0,
                        lineWidth: 15, 
                        percent: 1.0,
                        progressColor: Colors.green,
                        backgroundColor: GSColors.darkCloud,
                        center: Text ( 
                          '${user.diet[_dietKey][3].toString()}',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32.0),
                        ),
                        footer:   
                          Text(
                            "Calories Consumed",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20.0),
                          ),
                        
                      );
                    }
                    else if(user.diet[_dietKey] != null && snapshot.data['caloricGoal'] == 0)
                    {
                      return CircularPercentIndicator(
                        radius: 140.0,
                        lineWidth: 15,
                        percent: 0.0,
                        progressColor: GSColors.darkCloud,
                        backgroundColor: GSColors.darkCloud,
                        center: Text ( 
                          '${user.diet[_dietKey][3].toString()}',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32.0),
                        ),
                        footer:   
                          Text(
                            "Calories Consumed",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20.0),
                          ),
                      );
                    }

                    else
                    {
                      return CircularPercentIndicator(
                        radius: 140.0,
                        lineWidth: 15,
                        percent: 0,
                        progressColor: GSColors.darkCloud,
                        backgroundColor: GSColors.darkCloud,
                        footer:   
                          Text(
                            "Calories Consumed",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
                          ),
                      );
                    }
  
                  }
                )
              ),
            ),
            Container(
              child: _buildNutritionStats()
            )
          ],
        )
      ),
    ); 
  }

  Widget _buildNutritionStats() {
    return Container(
      //height: 320,
      margin: EdgeInsets.symmetric(vertical: 30, horizontal: 30),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
      ),
      child: Container(
        margin:EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin:EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Protein: ",
                    style: TextStyle(fontSize: 18.0, color: GSColors.darkBlue, fontWeight: FontWeight.w500)),
                  StreamBuilder(
                    stream: DatabaseHelper.getUserStreamSnapshot(DatabaseHelper.currentUserID),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      User user = User.jsonToUser(snapshot.data.data);

                      if(user.diet[_dietKey] == null)
                      {
                        return Text(
                          '0 g ',
                            style: TextStyle(fontSize: 18.0, color: GSColors.green, fontWeight: FontWeight.w500)
                        );                        
                      }
                      else
                      {
                        return Text(
                          '${user.diet[_dietKey][0].toString()} g ',
                            style: TextStyle(fontSize: 18.0, color: GSColors.green, fontWeight: FontWeight.w500)
                        );
                      }
                    
                    }
                  )
                ],
              )
            ),
            Container(
              margin:EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Carbs: ",
                    style: TextStyle(fontSize: 18.0, color: GSColors.darkBlue, fontWeight: FontWeight.w500)),
                  StreamBuilder(
                    stream: DatabaseHelper.getUserStreamSnapshot(DatabaseHelper.currentUserID),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      User user = User.jsonToUser(snapshot.data.data);
                      
                      if(user.diet[_dietKey] == null)
                      {
                        return Text(  
                          '0 g ',
                            style: TextStyle(fontSize: 18.0, color: GSColors.green, fontWeight: FontWeight.w500)
                        );                        
                      }
                      else
                      {
                        return Text(
                          '${user.diet[_dietKey][1].toString()} g ',
                            style: TextStyle(fontSize: 18.0, color: GSColors.green, fontWeight: FontWeight.w500)
                        );
                      } 
                    }
                  )
                ],
              )
            ),
            Container(
              margin:EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Fats: ",
                    style: TextStyle(fontSize: 18.0, color: GSColors.darkBlue, fontWeight: FontWeight.w500)),
                  StreamBuilder(
                    stream: DatabaseHelper.getUserStreamSnapshot(DatabaseHelper.currentUserID),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      User user = User.jsonToUser(snapshot.data.data);
                      
                      if(user.diet[_dietKey] == null)
                      {
                        return Text(
                          '0 g ',
                            style: TextStyle(fontSize: 18.0, color: GSColors.green, fontWeight: FontWeight.w500)
                        );                        
                      }
                      else
                      {
                        return Text(
                          '${user.diet[_dietKey][2].toString()} g ',
                            style: TextStyle(fontSize: 18.0, color: GSColors.green, fontWeight: FontWeight.w500)
                        );
                      }
                    }
                  )
                ],
              )
            ),
            Container(
              margin:EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Caloric Goal: ",
                        style: TextStyle(fontSize: 18.0, color: GSColors.darkBlue, fontWeight: FontWeight.w500)),
                  StreamBuilder(
                    stream: DatabaseHelper.getUserStreamSnapshot(DatabaseHelper.currentUserID),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      User user = User.jsonToUser(snapshot.data.data);

                        if(user.caloricGoal == null)
                        {
                          return Text('0 ',
                            style: TextStyle(fontSize: 18.0, color: GSColors.lightBlue, fontWeight: FontWeight.w500));
                        }
                        else
                        {
                          return Text('${user.caloricGoal.toString()}',
                            style: TextStyle(fontSize: 18.0, color: GSColors.lightBlue, fontWeight: FontWeight.w500));
                        }
                    }
                  )
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
}