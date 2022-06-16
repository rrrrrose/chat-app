import 'package:chat_app/basics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'Chat.dart';

class ChatSelector extends StatefulWidget {
  const ChatSelector({Key? key}) : super(key: key);

  @override
  State<ChatSelector> createState() => _ChatSelectorState();
}

class _ChatSelectorState extends State<ChatSelector> {

  _ChatSelectorState () {
    GrabChatPartners();
  }

  List<String> UIDs = [];
  List<String> PartnerNames = [];

  Future <void> GrabChatPartners() async
  {
    await FirebaseDatabase.instance.ref().child("userProfile").once()
        .then((event) {
          print("Successfully grabbed user profiles");
          var profiles = event.snapshot.value as Map;
          List<String> uid1 = [];
          List<String> partner1 = [];
          profiles.forEach((key, value) {
            print(key.toString() + " " + value.toString());
            if (key != getUID()){
            uid1.add(key.toString());
            partner1.add(value["Username"]);
            }
          });
          setState (() {
            UIDs = uid1;
            PartnerNames = partner1;
          });
    }).catchError((error){
      print("You failed to print user profile:" + error.toString());
    });
  }

  Widget UserButton(String name, String UID) {
    var thisImageWidget;

    //grab code here

    return SizedBox(
      height: 75,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: Color(0xff7986cb)
        ),
        onPressed: () {
          print(UID);
          Chat.partnerUID = UID;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Chat()),
          );
        },
        child: Row(
          children: [
            Container(
                margin: EdgeInsets.only(top: 7, bottom: 7, left: 7, right: 7),
                child: ClipOval(
                  //set thisImageWidget here
                    child: Image.network('https://upload.wikimedia.org/wikipedia/commons/8/89/Portrait_Placeholder.png')
                )
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )
              ),
            ),
          ],
        ),

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text ("Chat Selector"),
      ),
      body: Column(
        children: [
          Expanded(
              flex: 80,
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: UIDs.length,
                itemBuilder: (BuildContext context, int index) {
                  return
                  UserButton(PartnerNames[index], UIDs[index]);
                },
                separatorBuilder: (BuildContext context, int index) => const Divider(),
              )
          )
        ],
      ),
    );
  }
}
