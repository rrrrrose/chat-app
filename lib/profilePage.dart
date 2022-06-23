import 'dart:io';
import 'dart:ui';

import 'package:date_format/date_format.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:image_picker/image_picker.dart';

import 'ChatSelector.dart';
import 'Login.dart';
import 'Post.dart';
import 'basics.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);


  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  TextEditingController usernameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  var image;
  var imageWidget;

  int currentPageIndex = 0;
  String name = "";
  String description = "";
  List<String> date = [];
  List<String> content = [];

  bool validateName(String username) {
    return (username.length < 19);
  }

  bool validateDescription(String description) {
    return (description.length < 125);
  }

  Widget generatePostVisual(int index)
  {
    return Container(
      color: Color(0xffc9cfea),
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

  _ProfilePageState(){
    getUserInfo();
    getPost();
    GetImage();
    print("content of posts: " + content.toString());
  }

  Widget _buildPopupDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Edit your profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "New Username",
            style: TextStyle(

            ),
          ),
          TextField(
            maxLines: 1,
            controller: usernameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '',
            ),
          ),
          Text(
            "New Bio",
            style: TextStyle(

            ),
          ),
           TextField(
            minLines: 4,
            maxLines: 6,
            controller: descriptionController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: '',
            ),
          ),

          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: GallerySelection,

          ),



        ],
        //textfield: new username
        //textfield: new description
        //icon button for photo upload

      ),
      actions: <Widget>[
         Column(
           children: [
             ElevatedButton(
              onPressed: () {


                if (usernameController.text.isNotEmpty && validateName(usernameController.text)) changeUsername(usernameController.text);
                if (descriptionController.text.isNotEmpty && validateDescription(descriptionController.text)) changeDescription(descriptionController.text);
                if (image != null) changeProfilePic();

                usernameController.text = "";
                descriptionController.text = "";
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
           ],
         ),
      ],
    );

  }

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
            ProfilePicture(
              name: name,
              fontsize: 20,
              radius: 30,
        );
      });
    });
  }

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
                    padding: const EdgeInsets.only(top: 26, left: 8, right: 8, bottom: 8),
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
                                      builder: (BuildContext context) => _buildPopupDialog(context),
                                    );
                                  }, icon: Icon(Icons.settings))
                                ],
                              ),
                              Flexible(
                                  child:
                                  Text(description)
                              )
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

       ],
      ),
      body: <Widget>[
        homeScreenUI(),
        ChatSelector()
      ][currentPageIndex],
    );

  }
}
