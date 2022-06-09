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
      body: Column (
        children: [
          Expanded(
            flex: 25,
            child: Text("What's up?")
          ),
          Expanded (
            flex: 50,
              child: TextField(
                minLines: 10,
                maxLines: null,
                controller: textController,
                obscureText: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "",
                ),
          )
          ),
          ElevatedButton(onPressed: uploadPost, child: Text("Post"))
        ]
      )
    );
  }
}
