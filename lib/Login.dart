import 'package:chat_app/profilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'SignUp.dart';
class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  bool loginFailed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Login"),
        ) ,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 25, right: 25),
            child: Column (
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text("Email"),
                      TextField(
                        controller: emailController,
                        obscureText: false,
                      ),
                    ],
                  ),

                  TextField(
                    controller: passwordController,
                    obscureText: false,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Password",
                    ),
                  ),
                  if (loginFailed)
                    Text("Login Failed."),
                  ElevatedButton(onPressed: (){
                    FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text
                    ).then((value) {
                      print("You have successfully logged in.");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    }).catchError((error){
                      print("You failed to login.");
                      setState((){
                        loginFailed = true;
                      });
                    });
                  }, child: Text("Login")),
                  ElevatedButton(onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUp()),
                    );
                  }, child: Text("Signup")),
                  ElevatedButton(onPressed: (){
                    FirebaseDatabase.instance.ref().child("students/Victor").once().then((event) {
                      var info = event.snapshot.value as Map;
                      print(info["Age"]);
                      print(info["GPA"]);
                    }).catchError((error){
                      print("You failed to load information." + error.toString());
                    });
                  }, child: Text("Button")),
                  ElevatedButton(onPressed: (){
                    FirebaseDatabase.instance.ref().child("students/Rose").set(
                      {
                        "Name" : "Rose",
                        "Class" : "6",
                      }
                    ).then((event) {
                      print("You've successfully inputted info.");
                    }).catchError((error){
                      print("You failed to input information." + error.toString());
                    });
                  }, child: Text("Button2"))

                ]
            ),
          ),
        )
    );
  }
}


