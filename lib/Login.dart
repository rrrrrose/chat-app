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
        body: ListView(
          children: [
            Image (
              image: NetworkImage("https://www.creativefabrica.com/wp-content/uploads/2020/08/25/Chat-Logo-Design-Vector-Isolated-Graphics-5109821-1-1-580x387.jpg"),
            ),
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 0, bottom: 10),
                child: const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 20, bottom: 1, left: 35, right: 35),
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
                  margin: EdgeInsets.only(top: 20, bottom: 10, left: 35, right: 35),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Password",
                    ),
                  ),
                ),
                if (loginFailed)
                  Text(
                      "Wrong username or password. Try again.",
                      style: TextStyle (
                        color: Colors.red,
                      )
                  ),
              ],
            ),
            Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Color(0xff7986cb)
                      ),
                      onPressed: (){
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
                      }, child: const Text(
                      "Login",
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
                        MaterialPageRoute(builder: (context) => const SignUp()),
                      );
                    }, child: const Text(
                  "Don't have an account? Sign up here",
                  style: TextStyle(
                    fontSize: 18,
                    decoration: TextDecoration.underline,
                  ),

                )),
              ],
            ),
          ],
        )
    );
  }
}


