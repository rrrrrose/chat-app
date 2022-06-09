import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  bool signUpFailed = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Signup"),
      ) ,
      body: Center(
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
            Padding(
              padding: const EdgeInsets.only(top:30.0, bottom: 30.0),
              child: TextField(
                controller: usernameController,
                obscureText: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Username",
                ),
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Password",
              ),
            ),
            if (signUpFailed)
              Text("Signup Failed."),
            ElevatedButton(onPressed: (){
              FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text
              ).then((value) {
                print("You have successfully signed up.");
              }).catchError((error){
                print("You failed to signup.");
                setState((){
                  signUpFailed = true;
                });
              });
            }, child: Text("Signup")),
          ]
        ),
      )
    );
  }
}


