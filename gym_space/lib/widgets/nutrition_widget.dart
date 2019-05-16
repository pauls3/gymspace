

import 'package:GymSpace/misc/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../global.dart';

class NutritionWidget extends StatelessWidget {

  NutritionWidget({Key key}) : super(key: key);

  @override 
  Widget build(BuildContext context) {
    return Container();
  }

  void  updateNutritionInfo(BuildContext context, String _dietKey) async{
      int protein, carbs, fats, currentCalories = 0, caloricGoal;
      DocumentSnapshot macroDoc = await Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).get();//await Firestore.instance.collection('user').document(DatabaseHelper.currentUserID);
      Map<String, dynamic> macroFromDB = macroDoc.data['diet'].cast<String, dynamic>();
      int caloriesGoal = macroDoc.data['caloricGoal'];
      
    showDialog<String>(
      context: context,
      //child: SingleChildScrollView(
        //padding: EdgeInsets.all(5.0),
        child: AlertDialog(
        title: Text("Update your daily macros"),
        contentPadding: const EdgeInsets.all(16.0),
        content:  
          Container(
          //Row(
          // height: 350,
          // width: 350,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child:  TextField(
                keyboardType: TextInputType.number,
                maxLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Protein',
                  labelStyle: TextStyle(
                    fontSize: 18.0,
                    color: GSColors.darkBlue,
                  ),
                  contentPadding: EdgeInsets.all(10.0)
                ),
                onChanged: (text) {
                  (text != null) ? protein = int.parse(text): protein = 0;
                  //(text != null) ? currentCalories += protein * 4: currentCalories += 0;
                }
              ),
            ),
            
            Flexible(
              child:  TextField(
                keyboardType: TextInputType.number,
                maxLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Carbs',
                  labelStyle: TextStyle(
                    fontSize: 18.0,
                    color: GSColors.darkBlue,
                  ),
                  hintStyle: TextStyle(
                    fontSize: 16.0,
                    color: GSColors.darkBlue,
                  ),
                    contentPadding: EdgeInsets.all(10.0)
                ),
                onChanged: (text) { 
                  text != null ? carbs = int.parse(text) : carbs = 0;
                 // text != null ? currentCalories += carbs * 4 : currentCalories += 0;
                }
              ),
            ),
    
            Flexible(
              child:  TextField(
                keyboardType: TextInputType.number,
                maxLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Fats',
                  labelStyle: TextStyle(
                    fontSize: 18.0,
                    color: GSColors.darkBlue,
                  ),
                  hintStyle: TextStyle(
                    fontSize: 16.0,
                    color: GSColors.darkBlue,
                  ),
                    contentPadding: EdgeInsets.all(10.0)
                ),
                onChanged: (text) {
                    text != null ? fats = int.parse(text) : fats = 0;
                   // text != null ? currentCalories += fats * 9 : currentCalories += 0;
                }
              ),
            ),

             Flexible(
              child:  TextField(
                keyboardType: TextInputType.number,
                maxLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Caloric Goal',
                  labelStyle: TextStyle(
                    fontSize: 18.0,
                    color: GSColors.darkBlue,
                  ),
                  hintStyle: TextStyle(
                    fontSize: 16.0,
                    color: GSColors.darkBlue,
                  ),
                    contentPadding: EdgeInsets.all(10.0)
                ),
                onChanged: (text) {
                    text != null ? caloricGoal = int.parse(text) : caloricGoal = -1;
                }
              )
             )

          ],
        )),
        actions: <Widget>[
          FlatButton(
            child: const Text('Cancel'),
            onPressed: (){
              currentCalories = 0;
              Navigator.pop(context);
            }
          ),
          FlatButton(
            child: const Text('Save'),
            onPressed: (){

            // if(protein == null)
            //   protein = 0;
            // if(carbs == null)
            //   carbs = 0;
            // if(fats == null)
            //   fats = 0;
            // if(currentCalories == null)
            //   currentCalories = 0;
            // if(caloricGoal == null)
            //   caloricGoal = -1;

            // macroFromDB[_dietKey][0] = protein;
            // macroFromDB[_dietKey][1] = carbs;
            // macroFromDB[_dietKey][2] = fats;

            if(protein != null)
              macroFromDB[_dietKey][0] = protein;
            if(carbs != null)
              macroFromDB[_dietKey][1] = carbs;
            if(fats != null)
              macroFromDB[_dietKey][2] = fats;
            if(caloricGoal != null)
               Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
                {'caloricGoal': caloricGoal});
            macroFromDB[_dietKey][3] = macroFromDB[_dietKey][0] * 4 + macroFromDB[_dietKey][1] * 4 + macroFromDB[_dietKey][2] * 9;
            // if(caloricGoal != -1)
            //    Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
            //   {'caloricGoal': caloricGoal});
              // caloriesGoal = caloricGoal;
              //macroFromDB[_dietKey][4] = caloricGoal;
            
            currentCalories = 0;

            Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
              {'diet': macroFromDB});
            // Firestore.instance.collection('users').document(DatabaseHelper.currentUserID).updateData(
            //   {'caloricGoal': caloriesGoal});
            //_buildNutritionInfo(context);

            Navigator.pop(context);
            }
          )
        ],
      )
    );
  }
}
