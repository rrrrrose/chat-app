
import 'package:chat_app/basics.dart';
import 'package:chat_app/profilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'Login.dart';
class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {

  bool validateName(String username) {
    if (username.length > 18)
      {
        setState((){
          signUpFailed = true;
          failureMessage = "Username cannot exceed 18 characters.";
        });
        return false;
      }
    return true;
  }

  Future<void> setData() async{
    String UID = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance.ref().child("userProfile/"+UID).set(
        {
          "Username": usernameController.text,
          "Description": "",
        }).then((value){
      print("Successfully set default data.");
    }).catchError((error){
      print("Failed to set default data.");
    });
  }
  Future<void> signin() async{
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text
    ).then((value) {
      print("You have successfully logged in.");
    }).catchError((error){
      print("You failed to login.");
    });
  }
  Future<void> createUser() async{
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text
    ).then((value) {
      print("You have successfully created an user.");
    }).catchError((error){
      print("You failed to create an user.");

      setState((){
        signUpFailed = true;
        failureMessage = "Failed to create user.";
      });
    });
  }

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  bool signUpFailed = false;
  String failureMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView (
          children: [
            createTopTextWithColor('',Color(0xff7986cb) ),
            Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 20, bottom: 10),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 39,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 20, bottom: 15, left: 40, right: 40),
                  child: TextField(
                    controller: emailController,
                    obscureText: false,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Email",
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 20, bottom: 25, left: 40, right: 40),
                  child: TextField(
                    controller: usernameController,
                    obscureText: false,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Username",
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10, bottom: 25, left: 40, right: 40),
                  child: TextField(
                    controller: passwordController,
                    obscureText: false,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Password",
                    ),
                  ),
                ),
                if (signUpFailed)
                  Text(
                      failureMessage,
                      style: TextStyle (
                        color: Colors.red,
                      )
                  ),
                Container(
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Color(0xff7986cb)
                      ),
                      onPressed: (){
                        if (usernameController.text.isNotEmpty && validateName(usernameController.text)) createUser().
                    then((value){
                      signin().
                      then((value){
                        setData().
                        then((value){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                          );
                        });
                      });
                    });
                  }, child: const Text(
                      "Signup",
                      style: TextStyle (
                        fontSize: 22,
                      )
                  )),
                ),
                TextButton(
                    style: TextButton.styleFrom(
                      primary: Color(0xff7986cb)
                    ),
                    onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                }, child: const Text(
                  "Already have an account? Sign in ",
                  style: TextStyle(
                    fontSize: 18,
                    decoration: TextDecoration.underline,
                  ),

                )),
              ],
            ),

          ]
        ),
      )
    );
  }
}


