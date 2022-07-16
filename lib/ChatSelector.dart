import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat_app/basics.dart';
import 'dart:math';
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
    checkInvites().then((value) {
      GrabChatPartners();
    });

    checkPostCount();

  }

  List<String> UIDs = [];
  List<String> PartnerNames = [];
  List<Widget> profilePics = [];
  bool canSendRequest = false;


  Future <void> checkPostCount() async {
    FirebaseDatabase.instance.ref().child("userPost").child(getUID()).once().then((event){
      var info = event.snapshot.value as Map;
      setState ((){
        canSendRequest = (info.length > 0);
      });
    }).catchError((error){
      print("Cannot grab post count.");
    });
  }

  Future<void> checkInvites() async {
    //read all invites
    await FirebaseDatabase.instance.ref().child("userInvite").once().
    then((event) {
      var info = event.snapshot.value as Map;

      //check to see which ones contain "getUID()->"
      info.forEach((path, inviteAccepted) async {
        if (path.contains(getUID()+"->")) {
          //is it set to true?
          if (inviteAccepted) {
            //remove this path
            await FirebaseDatabase.instance.ref().child("userInvite").child(path).remove().
            then((value) {
              print("Removed invite. Both users are now friends");
            }).catchError((error) {
              print("Could not remove invite: " + error.toString());
            });

            //Add this friend to your friends list
            List<String> splitPath = path.split(">");
            await FirebaseDatabase.instance.ref().child("userFriend/"+getUID()).update(
                {
                  splitPath.last : splitPath.last,
                }
            ).then((event) {
              print("You've successfully added the friend.");
            }).catchError((error){
              print("You failed to add the friend." + error.toString());
            });
          }
        }
      });
    }).catchError((error) {

    });
  }

  Future <void> GrabChatPartners() async
  {
    List<String> uid1 = [];
    List<String> partner1 = [];

    //1. Get a list of all friends from FirebaseDatabase
    await FirebaseDatabase.instance.ref().child("userFriend/" + getUID()).once()
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
    await getAllImages();
  }

  Future<void> getAllImages() async {
    profilePics.clear();

    for(int i = 0; i<UIDs.length; i++)
    {
      print(i.toString());
      await getImage(i);
      setState((){});
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
      print("could not add: " + error.toString());
      profilePics.add(
          placeholderImg()
      );
    });
  }

  Widget UserButton(String name, String UID, Widget pic) {
    return SizedBox(
      height: 75,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Color(0xffc9cfea),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: Color(0xff7986cb),
                  width: 2,
              )
          ),
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
                child: pic
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black
                  )
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(onPressed: (){
                      removeFriend(UID);
                  }, icon: Icon(Icons.delete))
                ],
              ),
            )

          ],
        ),

      ),
    );
  }

  Future<dynamic> sentimentFriendSelector() async {
    String url = "https://userpostsentimentanalysis.marisabelchang.repl.co/" + getUID();
    String pickedUID;
    String pickedName = "";
    String pickedDescription = "";

    //Get a UID from the server
    var response = await http.get(Uri.parse(url)).
    catchError((error) {
      print("Could not get response: " + error.toString());
    });
    print(response.body.toString());
    var listData = jsonDecode(response.body.toString());

    pickedUID = listData[0].toString();
    if (pickedUID == getUID())
      {
        pickedUID = listData[1].toString();
      }
    print("RESULT: " + listData.toString());

    //Get the username and description
    await FirebaseDatabase.instance.ref().child("userProfile").child(pickedUID).once()
        .then((event) {
      print("Successfully grabbed profile for user " + pickedUID);
      var profile = event.snapshot.value as Map;

      pickedName = profile["Username"];
      pickedDescription = profile["Description"];

      print(pickedName);
      print(pickedDescription);
    }).catchError((onError) {
      print("Could not grab user profile for user " + pickedUID);
    });

    return [pickedUID, pickedName, pickedDescription];
  }

  Future <dynamic> debugFriendsSelector() async {
    List<String> UIDS = [];
    List<String> partners = [];
    List<String> descriptions = [];

    await FirebaseDatabase.instance.ref().child("userProfile").once()
        .then((event) {
      print("Successfully grabbed user profiles");
      var profiles = event.snapshot.value as Map;
      profiles.forEach((key, value) {
        print(key.toString() + " " + value.toString());
        bool isFriend = false;
        for (String UID in UIDs ){
          if (UID == key.toString())
            isFriend = true;
        }
        if (key != getUID() && isFriend == false){
          UIDS.add(key.toString());
          partners.add(value["Username"]);
          descriptions.add(value["Description"]);
        }
      });
    }).catchError((error){
      print("You failed to print user profile:" + error.toString());
    });

    //randomly pick value between 0 and UIDS.length
    int index = Random().nextInt(UIDS.length);


    //save lists at random value into variables
    String pickedUID = UIDS[index];
    String pickedName = partners[index];
    String pickedDescription = descriptions[index];

    print(pickedUID);
    print(pickedName);
    print(pickedDescription);

    return [pickedUID, pickedName, pickedDescription];
  }

  Future <void> removeFriend(String UID) async {
    //remove friend from your list
    await FirebaseDatabase.instance.ref().child("userFriend/" + getUID()).child(UID).remove()
        .then((event){
          print("You successfully removed friend.");
          GrabChatPartners();
    })
        .catchError((error){
          print("You failed to remove friend.");
    });

    //generate the convo name
    await FirebaseDatabase.instance.ref().child("userChat").child(generateConvoName(UID)).remove()
    .then((value) {
      print("Successfully deleted unfriended user's chat log");
    }).catchError((error) {
      print("Couldn't delete unfriended user's chat log: " + error.toString());
    });
  }

  Future<void> sendFriendRequest(String UID) async {
    await FirebaseDatabase.instance.ref().child("userInvite").update({
      getUID()+"->"+UID : false
    }).then((value) {
      print("Invite successful");
    }).catchError((error) {
      print("Could not send invite: " + error.toString());
    });
  }

  Widget addButton() {
    if (canSendRequest) {
      return FloatingActionButton(
        backgroundColor: Color(0xff7986cb),
        onPressed: () {
          sentimentFriendSelector().then((value){
            if (mounted)
              {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => _buildPopupDialog(context, value[0], value[1], value[2]),
                );
              }
          });
        },
        child: Icon(Icons.person_add),
      );
    } else {
      return const Text("You need at least one post");
    }
  }

  Widget _buildPopupDialog(BuildContext context, String UID, String username, String description) {
    return AlertDialog(
      title: Text('Recommended Friends'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              username,
              style: TextStyle(
                  fontSize: 20,
                  height: 1.5,
                  fontWeight: FontWeight.bold

            )
          ),
          Text(description),
          ]
      ),
      actions: <Widget>[
        Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Color(0xff7986cb)
              ),
              onPressed: () {
                sendFriendRequest(UID).then((value) => Navigator.of(context).pop());
              },
              child: const Text('Send Request'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  primary: Color(0xff7986cb)
              ),
              onPressed: () {
                Navigator.of(context).pop();

              },
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Selector"),
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
                  if (index < profilePics.length)
                    return UserButton(PartnerNames[index], UIDs[index], profilePics[index]);
                  else return Text("Loading...");
                },
                separatorBuilder: (BuildContext context, int index) => const Divider(),
              )
          )
        ],
      ),
      floatingActionButton: addButton()
    );
  }
}
