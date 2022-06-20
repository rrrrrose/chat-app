import 'package:chat_app/basics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

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
  List<ProfilePicture> profilePics = [];

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

    await GetAllImages();
  }

  Future<void> GetAllImages() async {
    int i = 0;
    while (i < UIDs.length)
      {
        await GetImage(i).then((value){
          i++;
        });
      }
  }

  Future <void> GetImage (int index) async {
    await FirebaseStorage.instance.ref().child("userProfile/" + UIDs[index] + "/" + "pic.jpeg").getDownloadURL()
        .then((url){
      setState(() {
        profilePics.add(
            ProfilePicture(
                name: PartnerNames[index],
                fontsize: 20,
                radius: 30,
                img: url,
              )
          );
        }
      );
      return;
    }).catchError((error){
      print("failed to grab the image" + error.toString());
      setState(() {
        profilePics.add(
            ProfilePicture(
              name: PartnerNames[index],
              fontsize: 20,
              radius: 30,
            )
        );
      });
    });
  }

  Widget UserButton(String name, String UID, ProfilePicture profilePic) {

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
                child: profilePic
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
                  if (index < profilePics.length)
                    return UserButton(PartnerNames[index], UIDs[index], profilePics[index]);
                  else return Text("haha could not load");
                },
                separatorBuilder: (BuildContext context, int index) => const Divider(),
              )
          )
        ],
      ),
    );
  }
}
