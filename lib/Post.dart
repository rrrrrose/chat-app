import 'package:chat_app/profilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
class Post extends StatefulWidget {
  const Post({Key? key}) : super(key: key);

  @override
  State<Post> createState() => _PostState();
}

class _PostState extends State<Post> {
  TextEditingController textController = TextEditingController();
  Future<void> uploadPost() async
  {
    if(textController.text.isEmpty)
      return;
    String UID = FirebaseAuth.instance.currentUser!.uid;
    int time = DateTime.now().millisecondsSinceEpoch;
    FirebaseDatabase.instance.ref().child("userPost/"+UID).update(
        {
          time.toString() : textController.text,
        }
    ).then((event) {
      print("You've successfully inputted info.");
    }).catchError((error){
      print("You failed to input information." + error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xfff2f3fa),
      body: Column (
        children: [
          Expanded(
            flex: 30,
            child: Text("")
          ),
          Expanded (
            flex: 50,
              child: Container(
                margin: EdgeInsets.only(top: 20, bottom: 15, left: 20, right: 20),
                child: TextField(
                  minLines: 10,
                  maxLines: null,
                  controller: textController,
                  obscureText: false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "How are you feeling today?",
                  ),
          ),
              )
          ),
          Expanded(
            flex: 10,
            child: Container(
              margin: EdgeInsets.only(right: 20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(onPressed: (){
                    uploadPost().then((value){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    });
                  },
                      style: ElevatedButton.styleFrom(
                          primary: Color(0xff7986cb)
                      ),
                      child: Text("Post")),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(""),
          )
        ]
      )
    );
  }
}
