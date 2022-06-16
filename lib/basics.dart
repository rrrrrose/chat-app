import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

String getUID()
{
  return FirebaseAuth.instance.currentUser!.uid;
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