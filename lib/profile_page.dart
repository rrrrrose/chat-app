import 'dart:io';
import 'dart:ui';

import 'package:chat_app/chat_requests.dart';
import 'package:date_format/date_format.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_selector.dart';
import 'sign_in.dart';
import 'post.dart';
import 'basics.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);


  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  //used to let user change their profile
  TextEditingController usernameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  //used to delete account
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  //stores user's profile pic (if it exists)
  var image;
  var imageWidget;

  int currentPageIndex = 0;

  //will eventually match the user's profile info
  String name = "";
  String description = "";

  //will eventually store user's posts
  List<String> date = [];
  List<String> content = [];

  _ProfilePageState(){
    getUserInfo();
    getPost();
    GetImage();
    print("content of posts: " + content.toString());
  }

  //grabs the user's profile information and profile pic
  Future<void> getUserInfo() async {
    String UID = FirebaseAuth.instance.currentUser!.uid;
    FirebaseDatabase.instance.ref().child("userProfile/"+UID).once().then((event) {
      print("Retrived username and password");
      var info = event.snapshot.value as Map;
      setState((){
        name = info["Username"];
        print(name);
        description = info["Description"];
        print(description);
      });
    }).catchError((error){
      print("You failed to load information." + error.toString());
    });
  }

  //grabs the user's posts
  Future<void> getPost() async {
    String UID = FirebaseAuth.instance.currentUser!.uid;
    FirebaseDatabase.instance.ref().child("userPost/"+UID).once().
    then((event) {
      var info = event.snapshot.value as Map;
      print("Grabbed info: " + info.toString());
      List<String> grabbedDate = [];
      List<String> grabbedContent = [];
      info.forEach((key, value) {
        grabbedDate.add(key);
      });

      //sort timestamps
      grabbedDate.sort((a,b)=>int.parse(b).compareTo(int.parse(a)));

      //add date based on sorted timestamp
      for (var timestamp in grabbedDate) {
        grabbedContent.add(info[timestamp]);
      }

      setState((){
        date = grabbedDate;
        content = grabbedContent;
      });
    }).catchError((error){
      print("You failed to load post." + error.toString());
    });

  }

  //ensure that name is at most 18 characters
  bool validateName(String username) {
    return (username.length < 19);
  }

  //ensure that the description is under 125 characters
  bool validateDescription(String description) {
    return (description.length < 125);
  }

  //presents the pop up to ask user for confirmation for account deletion
  Widget showDeletionPopUp(BuildContext context) {
    return AlertDialog(
      title: Text("Confirm deletion"),
      content: Text("To confirm deletion, enter in your sign-in credentials:"),
      actions: <Widget>[
        TextField(
          controller: emailController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Email',
          ),
        ),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Password',
          ),
        ),
        ElevatedButton(
          onPressed: () {
            tryDeleteAccount();
          },
          child: const Text('Yes, delete my account'),
        ),
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("No")
        )
      ],
    );

  }

  //attempts to delete user's account
  Future<void> tryDeleteAccount() async {
    //sign in first
    //firebase will only let an account be deleted if it was authenticated at most 5 minutes prior to the operation request
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text
    ).then((value) async {
      //once the account has been verified, go ahead and start deleting data
      print("Account signed in. Deletion verified.");
      await deleteAccountData();
    }).catchError((error) {
      print("Could not delete account: " + error.toString());
    });
  }

  //deletes anything in the database that is related to the user's UID
  Future<void> deleteAccountData() async {
    await deleteProfileInfo();
    await deleteProfilePic();
    await deletePosts();
    await deleteChatLogs();
    await deleteAllFriends(); //delete yourself from other friend's list
    await deleteFriendsList(); //delete your own friends list
    await deleteInviteList();
    await deleteAuthAccount();

    //sign out the user
    await FirebaseAuth.instance.signOut().then((value) {
      print("signed out");
    }).catchError((error) {
      print("could not sign out");
    });

    //kick out to login page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  //deletes user's profile info
  Future<void> deleteProfileInfo() async {
    await FirebaseDatabase.instance.ref().child("userProfile").child(getUID()).remove().then((value) {
      print("Profile info successfully deleted");
    }).catchError((error) {
      print("Could not delete profile info: " + error.toString());
    });
  }

  //deletes user's posts
  Future<void> deletePosts() async {
    await FirebaseDatabase.instance.ref().child("userPost").child(getUID()).remove().then((value) {
      print("Posts successfully deleted");
    }).catchError((error) {
      print("Could not delete posts: " + error.toString());
    });
  }

  //deletes all chat logs containing user's UID
  Future<void> deleteChatLogs() async {
    await FirebaseDatabase.instance.ref().child("userFriend").child(getUID()).once().then((event) {
      //map of all friends
      var info = event.snapshot.value as Map;
      List<String> convoPathsToRemove = [];

      info.forEach((friendUID, value) {
        convoPathsToRemove.add(generateConvoName(friendUID));
      });

      int index = convoPathsToRemove.length-1;
      Future.doWhile(() async {
        await FirebaseDatabase.instance.ref().child("userChat").child(convoPathsToRemove[index]).remove().then((value) {
          print("Deleted chat log: " + convoPathsToRemove[index]);
        }).catchError((error) {
          print("Could not delete chat log: " + error.toString());
        });

        index--;
        return (index > 0);
      });

      print("Deleted all convo logs");
    }).catchError((error) {
      print("Could not delete all logs: " + error.toString());
    });
  }

  //deletes the user's personal friends list
  Future<void> deleteFriendsList() async {
    await FirebaseDatabase.instance.ref().child("userFriend").child(getUID()).remove().then((value) {
      print("Deleted your friends list.");
    }).catchError((error) {
      print("Could not delete your friends list: " + error.toString());
    });
  }

  //delete's the user from all their other friends' lists
  Future<void> deleteAllFriends() async {
    await FirebaseDatabase.instance.ref().child("userFriend").child(getUID()).once().then((event) {
      //map of all friends
      var info = event.snapshot.value as Map;
      List<String> friendsToRemove = [];

      info.forEach((friendUID, value) {
        friendsToRemove.add(friendUID);
      });

      int index = friendsToRemove.length-1;
      Future.doWhile(() async {
        await FirebaseDatabase.instance.ref().child("userFriend").child(friendsToRemove[index]).child(getUID()).remove().then((value) {
          print("found me");
        }).catchError((error) {
          print("Could not delete friend: " + error.toString());
        });
        
        index--;
        return (index > 0);
      });

      print("Unfriended all friends.");
    }).catchError((error) {
      print("Could not unfriend everyone: " + error.toString());
    });
  }

  //deletes the user's profile pic (if there is one)
  Future<void> deleteProfilePic() async {
    await FirebaseStorage.instance.ref().child("userProfile/" + getUID() + "/" + "pic.jpeg").delete().then((value) {
      print("Profile pic successfully deleted");
    }).catchError((error) {
      print("Could not delete profile picture: " + error.toString());
    });
  }

  //deletes any invites the user has sent that are still open
  Future<void> deleteInviteList() async {
    //read all invites
    //if invite contains "getUID()->", delete that
    await FirebaseDatabase.instance.ref().child("userInvite").once().
    then((event) {
      var info = event.snapshot.value as Map;

      //check to see which ones contain UID
      info.forEach((path, inviteAccepted) async {
        if (path.contains(getUID())) {
          await FirebaseDatabase.instance.ref().child("userInvite").remove().
          then((value) {
            print("Invite deleted: " + path);
          }).catchError((error) {
            print("Could not delete invite: " + error.toString());
          });
        }
      });
    }).catchError((error) {
      print("Could not delete all invites: " + error.toString());
    });
  }

  //delete's user's account from authentication services
  Future<void> deleteAuthAccount() async {
    await FirebaseAuth.instance.currentUser!.delete().then((value) {
      print("Account successfully deleted.");
    }).catchError((error) {
      print("Could not delete account: " + error.toString());
    });
  }

  //creates a widget containing info about a post
  Widget generatePostVisual(int index)
  {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffc9cfea),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        border: Border.all(
            width: 2,
            color: Color(0xff7986cb)
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
        mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                    formatDate(DateTime.fromMillisecondsSinceEpoch(int.parse(date[index])), [mm, '/', dd, '/', yy, ' ', hh, ":", nn]),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      fontSize: 21,
                    )
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(left:6, right: 6),
                    child: Text(
                        "       " + content[index],
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.5
                        )
                    ),
                  ),
                ),
              ],
            )
          ]
        ),
      ),
    );
  }

  //shows a popup that lets the user edit their name, description, and profile picture
  Widget showEditPopUp(BuildContext context) {
    return AlertDialog(
      title: Text('Edit your profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("New Username"),
          TextField(
            maxLines: 1,
            controller: usernameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '',
            ),
          ),
          Text("New Bio"),
           TextField(
            minLines: 4,
            maxLines: 6,
            controller: descriptionController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: GallerySelection,
          ),
        ],
      ),
      actions: <Widget>[
         Row(
           mainAxisAlignment: MainAxisAlignment.end,
           children: [
             ElevatedButton(
              onPressed: () {
                //validate inputs
                if (usernameController.text.isNotEmpty && validateName(usernameController.text)) changeUsername(usernameController.text);
                if (descriptionController.text.isNotEmpty && validateDescription(descriptionController.text)) changeDescription(descriptionController.text);
                if (image != null) changeProfilePic();

                //set texts to empty
                usernameController.text = "";
                descriptionController.text = "";

                //get rid of popup
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
        ),
             TextButton(
                 style: TextButton.styleFrom(
                     primary: Color(0xff7986cb)
                 ),
                 onPressed: (){
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const Login()),
                   );
                 }, child: const Text(
               "Sign Out",
               style: TextStyle(
                 fontSize: 15,
                 decoration: TextDecoration.underline,
               ),
             )),
             TextButton(
                 style: TextButton.styleFrom(
                     primary: Color(0xff7986cb)
                 ),
                 onPressed: (){
                   Navigator.pop(context);
                   showDialog(
                     context: context,
                     builder: (BuildContext context) => showDeletionPopUp(context),
                   );
                 }, child: const Text(
               "Delete Account",
               style: TextStyle(
                 fontSize: 15,
                 decoration: TextDecoration.underline,
               ),

             )),
           ],
         ),
      ],
    );

  }

  //changes the user's username
  Future <void> changeUsername(String newName) async {
    await FirebaseDatabase.instance.ref().child("userProfile/" + getUID()).update(
      {
        'Username' : newName,
      }
    ).then((event){
      print("successfully updated username");
      setState ((){
        name = newName;
      });
    }).catchError((error){
      print("failed to update username");
    });
  }

  //changes the user's description
  Future <void> changeDescription(String newDescription) async {
    await FirebaseDatabase.instance.ref().child("userProfile/" + getUID()).update(
        {
          'Description' : newDescription,
        }
    ).then((event){
      print("successfully updated user description");
      setState ((){
        description = newDescription;
      });
    }).catchError((error){
      print("failed to update user description");
    });
  }

  //changes the user's profile pic
  Future<void> changeProfilePic() async
  {
    await FirebaseStorage.instance.ref().child("userProfile/" + getUID() + "/" + 'pic.jpeg').putFile(File(image.path))
        .then((result){
      print("successfully updated the profile pic");
      GetImage();
    }).catchError((error){
      print("failed to update the profile pic" + error.toString());
    });
  }

  //fetches the user's profile pic from firestore (if there is one)
  Future <void> GetImage () async {
    FirebaseStorage.instance.ref().child("userProfile/" + getUID() + "/" + "pic.jpeg").getDownloadURL()
        .then((url){
          print("grabbed the image");
          setState(() {
            imageWidget =  ProfilePicture(
              name: name,
              fontsize: 20,
              radius: 50,
              img: url,
              random: true,
            );
          });
          return;
    }).catchError((error){
      print("failed to grab the image" + error.toString());
      setState(() {
        imageWidget =
            placeholderImg();
      });
    });
  }

  //brings up image gallery so the app can get a pic from the user
  Future <void> GallerySelection () async {
    await ImagePicker().pickImage(source: ImageSource.gallery)
        .then((event){
          print("Successfully grabbed the image");
          image = event;

    }).catchError((error){
      print("Failed to grab the image");
    });

  }

  Widget homeScreenUI()
  {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Post()),
        );
      },
          backgroundColor: Color(0xff7986cb),
          child: const Icon (Icons.add)
      ),
      body: Container(
        color: Color(0xfff2f3fa),
        child: Column(
          children: [
            Expanded(
                flex: 25,
                child: Container(
                  color: Color(0xff7986cb),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, left: 8, right: 8),
                    child: Row (
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Container (
                            width: 100,
                              height: 100,
                              child: imageWidget,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: Text(
                                            name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          )
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(onPressed: (){
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) => showEditPopUp(context),
                                    );
                                  }, icon: Icon(Icons.settings))
                                ],
                              ),
                              Flexible(
                                  child:
                                  Text(description)
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                )
            ),
            Container(

              child: Expanded(
                flex: 75,
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: content.length,
                  itemBuilder: (BuildContext context, int index) {
                    return generatePostVisual(index);
                  },
                  separatorBuilder: (BuildContext context, int index) => const Divider(),
                ),
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
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
          currentPageIndex = index;
        });
      },
      selectedIndex: currentPageIndex,
      destinations: const <Widget>[
        NavigationDestination(
        icon: Icon(Icons.home),
        label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat),
        label: 'Chat',
       ),
        NavigationDestination(
          icon: Icon(Icons.person_add),
          label: 'Invites',
        ),

       ],
      ),
      body: <Widget>[
        homeScreenUI(),
        ChatSelector(),
        ChatRequests()
      ][currentPageIndex],
    );

  }
}
