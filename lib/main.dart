import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:chat_app/profile_page.dart';
import 'package:flutter/material.dart';

import 'sign_in.dart';
import 'post.dart';
import 'sign_up.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SansPro',

        primarySwatch: Colors.indigo,
      ),
      home: Login(),
    );
  }
}

