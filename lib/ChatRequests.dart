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
  List<String> PartnerDescription = [];
  List<Widget> profilePics = [];

  _ChatRequestsState()
  {
    GrabChatInvites();
  }

  Future<void> GrabChatInvites() async {
    //all temporary lists
    List<String> temp_uids= [];
    List<String> temp_partners = [];
    List<String> temp_descs = [];

    //1. Get a list of all invite paths from FirebaseDatabase
    await FirebaseDatabase.instance.ref().child("userInvite").once().
    then((event) {
      var info = event.snapshot.value as Map;

      info.forEach((path, inviteAccepted) {
        if (inviteAccepted == false && path.contains("->"+getUID()))
          {
            print(path + ":" + inviteAccepted.toString());
            //split the path/isolate last UID
            List<String> splitPath = path.split("-");

            //add the first part of the path (the other user's UID)
            temp_uids.add(splitPath.first);
          }
      });
    }).
    catchError((error) {
      print("You failed to grab all invitations:" + error.toString());
    });

    //2. Look up friend UIDS through FirebaseDatabase to get names
    await FirebaseDatabase.instance.ref().child("userProfile").once()
        .then((event) {
      print("Successfully grabbed user profiles");
      var profiles = event.snapshot.value as Map;
      for(String u in temp_uids){
        temp_partners.add(profiles[u]['Username']);
        temp_descs.add(profiles[u]["Description"]);
      }

      setState (() {
        UIDs = temp_uids;
        PartnerNames = temp_partners;
        PartnerDescription = temp_descs;
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
          setState(() {
            profilePics.add(
                ProfilePicture(
                  name: PartnerNames[index],
                  fontsize: 20,
                  radius: 30,
                  img: url,
                )
            );
          });
    }).catchError((error) {
      profilePics.add(
          placeholderImg()
      );
    });
  }

  Widget UserButton(String name, String UID, Widget pic, String description) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 75,
      ),
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
              width: MediaQuery.of(context).size.width * 0.12,
              child: pic
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    )
                ),
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: MediaQuery.of(context).size.width * 0.60),
                  child: Text(
                    description
                  ),
                )
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                  onPressed: ()
                  {
                    addFriend(UID).then((value) => GrabChatInvites());
                    },
                  icon: Icon(Icons.add))
            ],
          )
        ],
      ),
    );
  }

  Future <void> addFriend(String UID) async {
    //generate the path name
    //the other user sent the invite, so it's their UID, then ours
    String pathName = UID + "->" + getUID();

    await FirebaseDatabase.instance.ref().child("userInvite").update({
      pathName : true
    }).
    then((value) {
      print("Invite accepted");
    }).catchError((error) {
      print("Invite could not be accepted: " + error.toString());
    });

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

    GrabChatInvites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Requests"),
        backgroundColor: Color(0xff7986cb),
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
                    return UserButton(PartnerNames[index], UIDs[index], profilePics[index], PartnerDescription[index]);
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
