import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

import 'Chat.dart';
import 'basics.dart';

class ChatRequests extends StatefulWidget {
  const ChatRequests({Key? key}) : super(key: key);

  @override
  State<ChatRequests> createState() => _ChatRequestsState();
}

class _ChatRequestsState extends State<ChatRequests> {

  List<String> UIDs = [];
  List<String> PartnerNames = [];
  List<ProfilePicture> profilePics = [];

  _ChatRequestsState()
  {
    GrabChatInvites();
  }

  Future<void> GrabChatInvites() async {
    List<String> uid1 = [];
    List<String> partner1 = [];

    //1. Get a list of all invites from FirebaseDatabase
    await FirebaseDatabase.instance.ref().child("userInvite/" + getUID()).once()
        .then((event) {
      print("Successfully grabbed your list of friends");
      var friends = event.snapshot.value as Map;

      friends.forEach((key, value) {
        print(key.toString());
        uid1.add(key);
      });
    }).catchError((error){
      print("You failed to grab your list of friends:" + error.toString());
    });

    //2. Look up friend UIDS through FirebaseDatabase to get names
    await FirebaseDatabase.instance.ref().child("userProfile").once()
        .then((event) {
      print("Successfully grabbed user profiles");
      var profiles = event.snapshot.value as Map;
      List<String> partner1 = [];
      for(String u in uid1){
        partner1.add(profiles[u]['Username']);
      }

      setState (() {
        UIDs = uid1;
        PartnerNames = partner1;
      });
    }).catchError((error){
      print("You failed to print user profile:" + error.toString());
    });

    //3. Generate profile picture per friend UID
    await getAllImages();
    print("Profile Pics: " + profilePics.length.toString());

    //4. Reload page
    setState(() {});
  }

  Future<void> getAllImages() async {
    profilePics.clear();

    for(int i = 0; i<UIDs.length; i++)
    {
      print(i.toString());
      await getImage(i);
    }
  }

  Future<void> getImage(int index) async {
    String UIDToLookUp = UIDs[index];
    await FirebaseStorage.instance.ref().child("userProfile").child(UIDToLookUp).child("pic.jpeg").getDownloadURL()
        .then((url) {
      profilePics.add(
          ProfilePicture(
            name: PartnerNames[index],
            fontsize: 20,
            radius: 30,
            img: url,
          )
      );
    }).catchError((error) {
      profilePics.add(
          ProfilePicture(
            name: PartnerNames[index],
            fontsize: 20,
            radius: 30,
          )
      );
    });
  }

  Widget UserButton(String name, String UID, ProfilePicture pic) {
    return SizedBox(
      height: 75,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xffc9cfea),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          border: Border.all(
              width: 2,
              color: Color(0xff7986cb)
          ),
        ),
        child: Row(
          children: [
            Container(
                margin: EdgeInsets.only(top: 7, bottom: 7, left: 7, right: 7),
                child: pic
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  )
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      onPressed: ()
                      {
                        addFriend(UID).then((value) => GrabChatInvites());
                        },
                      icon: Icon(Icons.add))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future <void> addFriend(String UID) async {
    //Add this friend to your friends list
    FirebaseDatabase.instance.ref().child("userFriend/"+getUID()).update(
        {
          UID : UID,
        }
    ).then((event) {
      print("You've successfully added the friend.");
    }).catchError((error){
      print("You failed to add the friend." + error.toString());
    });

    //Add yourself to other guy's list
    FirebaseDatabase.instance.ref().child("userFriend/"+UID).update(
        {
          getUID() : getUID(),
        }
    ).then((event) {
      print("Other user's friend's list updated.");
    }).catchError((error){
      print("Other user's friend's list failed to update: " + error.toString());
    });

    //Remove from invites list
    FirebaseDatabase.instance.ref().child("userInvite").child(getUID()).child(UID).remove()
    .then((event) {
      print("Invite accepted");
    }).catchError((error) {
      print("Failed to accept the invite " + error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Requests"),
      ),
      body: Column(
        children: [
          Expanded(
              flex: 80,
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: UIDs.length,
                itemBuilder: (BuildContext context, int index) {
                  if (index < profilePics.length) {
                    return UserButton(PartnerNames[index], UIDs[index], profilePics[index]);
                  } else return Text("Loading...");
                },
                separatorBuilder: (BuildContext context, int index) => const Divider(),
              )
          )
        ],
      ),
    );
  }
}
