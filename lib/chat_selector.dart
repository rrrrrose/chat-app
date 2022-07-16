import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chat_app/basics.dart';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

import 'chat.dart';

class ChatSelector extends StatefulWidget {
  const ChatSelector({Key? key}) : super(key: key);

  @override
  State<ChatSelector> createState() => _ChatSelectorState();
}

class _ChatSelectorState extends State<ChatSelector> {

  List<String> UIDs = [];
  List<String> partnerNames = [];
  List<Widget> profilePics = [];
  bool canSendRequest = false;

  _ChatSelectorState () {
    checkInvites().then((value) {
      grabChatPartners();
    });
    checkPostCount();
  }

  //checks how many posts the user has made
  //the user can't ask for a friend recommendation unless they post at least once
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

  //checks any invites the user has sent out
  //if any invite was accepted, then add a new friend to the user's friend list
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

  //gets a list of all the users friends
  Future <void> grabChatPartners() async
  {
    List<String> temp_uids = [];
    List<String> temp_partners = [];

    //1. Get a list of all friends from FirebaseDatabase
    await FirebaseDatabase.instance.ref().child("userFriend/" + getUID()).once()
        .then((event) {
      print("Successfully grabbed your list of friends");
      var friends = event.snapshot.value as Map;

      friends.forEach((key, value) {
        print(key.toString());
        temp_uids.add(key);
      });
    }).catchError((error){
      print("You failed to grab your list of friends:" + error.toString());
    });

    //2. Look up friend UIDS through FirebaseDatabase to get names
    await FirebaseDatabase.instance.ref().child("userProfile").once()
        .then((event) {
          print("Successfully grabbed user profiles");
          var profiles = event.snapshot.value as Map;
          for(String u in temp_uids){
            temp_partners.add(profiles[u]['Username']);
          }

          setState (() {
            UIDs = temp_uids;
            partnerNames = temp_partners;
          });
    }).catchError((error){
      print("You failed to print user profile:" + error.toString());
    });
    await getAllImages();
  }

  //fetches a collection of all the user's friends' profile pics
  Future<void> getAllImages() async {
    profilePics.clear();

    for(int i = 0; i<UIDs.length; i++)
    {
      print(i.toString());
      await getImage(i);
      setState((){});
    }
  }

  //fetches a profile pic given an index from the UID list
  Future<void> getImage(int index) async {
    String UIDToLookUp = UIDs[index];
    await FirebaseStorage.instance.ref().child("userProfile").child(UIDToLookUp).child("pic.jpeg").getDownloadURL()
        .then((url) {
      profilePics.add(
          ProfilePicture(
            name: partnerNames[index],
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

  //creates a widget that contains information about a user's given friend.
  //when tapped, it will navigate to a chat page.
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

  //recommend a friend using a sentiment analysis AI
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

  //recommend a friend using a random number generator
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

  //get rid of a friend and the subsequent chat log
  Future <void> removeFriend(String UID) async {
    //remove friend from your list
    await FirebaseDatabase.instance.ref().child("userFriend/" + getUID()).child(UID).remove()
        .then((event){
          print("You successfully removed friend.");
          grabChatPartners();
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

  //creates an invite log in firebase database
  Future<void> sendFriendRequest(String UID) async {
    await FirebaseDatabase.instance.ref().child("userInvite").update({
      getUID()+"->"+UID : false
    }).then((value) {
      print("Invite successful");
    }).catchError((error) {
      print("Could not send invite: " + error.toString());
    });
  }

  //a "recommend me a friend" button
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
                  builder: (BuildContext context) => showRecommendationPopUp(context, value[0], value[1], value[2]),
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

  //show a popup after a recommendation has been found.
  Widget showRecommendationPopUp(BuildContext context, String UID, String username, String description) {
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
                    return UserButton(partnerNames[index], UIDs[index], profilePics[index]);
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
