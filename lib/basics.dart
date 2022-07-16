import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//get the signed in user's UID.
String getUID()
{
  return FirebaseAuth.instance.currentUser!.uid;
}

//a reference for a placeholder profile pic.
//the picture is creative commons from wikimedia.
Widget placeholderImg()
{
  return ClipOval(child: Image.network('https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg'));
}

//creates a convo name given a UID.
//it combines it with the signed in user's UID.
//the order is lexicographical (alphabetical)
String generateConvoName (String partnerUID){
  List<String> NameList = [getUID(), partnerUID];
  NameList.sort(); //alphabetically
  return NameList[0] + "-" + NameList[1];
}

//creates a top bar for screens.
//String topText - what should the top bar say?
//Color topColor - what color should the top bar be?
Widget createTopTextWithColor(String topText, Color topColor)
{
  return Container(
    height: 60,
    color: topColor,
    alignment: Alignment.center,
    child: Text(
      topText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}