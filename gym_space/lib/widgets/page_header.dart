import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:GymSpace/misc/colors.dart';

class PageHeader extends StatelessWidget {
  final Widget child;
  final String title;
  final Color backgroundColor;
  final Color titleColor;
  final bool showDrawer;
  final bool showSearch;
  final Function searchFunction;
  final double fontsize;

  PageHeader({
    this.title, 
    this.backgroundColor, 
    this.fontsize = 26,
    Key key, 
    this.child, 
    this.showDrawer = false, 
    this.showSearch = false,
    this.searchFunction,
    this.titleColor = Colors.white}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AppBar(
        iconTheme: IconThemeData(color: titleColor),
        backgroundColor: backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(bottom: Radius.circular(40))
        ),
        leading: showDrawer ? null : IconButton(
          icon: Icon(
            Icons.keyboard_arrow_left, 
            color: titleColor, 
            size: 24,
          ),
          onPressed: () {Navigator.pop(context);},
        ),
        actions: <Widget>[
          showSearch ? IconButton(
            icon: Icon(
              Icons.search,
              color: titleColor,
              size: 26,
            ),
            onPressed: searchFunction == null ? null : searchFunction,
          ) : Container()
        ],
        bottom: PreferredSize(
          child: Container(
            margin: EdgeInsets.only(bottom: 40),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontsize,
                letterSpacing: 4,
                color: titleColor,
              ),
            ),
          ), preferredSize: null,
        )
      ),
    );
  }
}