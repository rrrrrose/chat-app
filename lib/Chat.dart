import 'package:bubble/bubble.dart';
import 'package:chat_app/basics.dart';
import 'package:date_format/date_format.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);
  static String partnerUID = "";

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  TextEditingController ChatController = TextEditingController();

  String get partnerUID => Chat.partnerUID;
  String convoName = "";

  var _posts = [];

  String currentUsersName = "";
  String partnersName = "";
  ScrollController listScrollController = ScrollController();

  _ChatState()
  {
    //generate convo name
    convoName = GenerateConvoName();

    //get chat log
    GetChatLogs();

    //get user names
    GetUsername();

    //update chat logs whenever firebase changes
    FirebaseDatabase.instance.ref().child("userChat/" + convoName).onChildAdded.listen((event) {
      GetChatLogs();
    });
  }

  Future <void> GetChatLogs () async {
    await FirebaseDatabase.instance.ref().child("userChat/" + convoName).once()
        .then((event) {
      print("Successfully grabbed user chat");
      var chat = event.snapshot.value as Map;
      var p = [];

      chat.forEach((key, value) {
        p.add(value);
        print(value.toString());
      });
      p.sort((a,b)=>a["timestamp"].compareTo(b['timestamp']));

      setState((){
        _posts = p;
      });
    }).catchError((error){
      print("You failed to load user chat:" + error.toString());
    });
  }
  
  Future <void> GetUsername() async {
    print(convoName);

    String currentUID = FirebaseAuth.instance.currentUser!.uid;
    print(currentUID);
    await FirebaseDatabase.instance.ref().child("userProfile/" + currentUID).once()
    .then((event){
      print("Found username");
      var info = event.snapshot.value as Map;
      setState((){
        currentUsersName = info["Username"];
      });
    }).catchError((error){
      print("Failed to load username");

    });

    print(partnerUID);
    await FirebaseDatabase.instance.ref().child("userProfile/" + partnerUID).once()
        .then((event){
      print("Found partner username");
      var info = event.snapshot.value as Map;
      setState((){
        partnersName = info["Username"];
      });
    }).catchError((error){
      print("Failed to load partner username");

    });
  }

  Future <void> sendMessage() async {
    await FirebaseDatabase.instance.ref().child("userChat/" + convoName + "/" + DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      'timestamp' : DateTime.now().millisecondsSinceEpoch,
      'author' : FirebaseAuth.instance.currentUser!.uid,
      'content' : ChatController.text,
    }).then((event){
      print("message sent");
      ChatController.text = '';
    }).catchError((error){
      print("failed to send the message");
    });
  }

  Widget loadMessage(int index) {
    var post = _posts[index];
    int timeStamp = post["timestamp"];
    String formattedTimeStamp = formatDate(
        DateTime.fromMillisecondsSinceEpoch(timeStamp),
        [mm, '/', dd, '/', yyyy, ' ', hh, ':', nn]
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 250,
                    child: Bubble(
                      color: Colors.indigo[200],
                      nip: BubbleNip.rightBottom,
                      child: Text(post["content"], style: TextStyle(
                        fontSize: 17,
                      ),),
                    ),

                ),
                Text(formattedTimeStamp)
              ],
            ),
            /*
            Container(
                width: 50,
                height: 50,
                child: ClipOval(child: Image.network('https://upload.wikimedia.org/wikipedia/commons/8/89/Portrait_Placeholder.png'))
            )
             */
          ],
        )
      ),
    );

  }

  Widget loadPartnerMessage(int index) {
    var post = _posts[index];
    int timeStamp = post["timestamp"];
    String formattedTimeStamp = formatDate(
        DateTime.fromMillisecondsSinceEpoch(timeStamp),
        [mm, '/', dd, '/', yyyy, ' ', hh, ':', nn]
    );
    var thisImageWidget;

    //grab code here

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 250,
                    child: Bubble(
                      color: Colors.indigo[200],
                      nip: BubbleNip.leftBottom,
                      child: Text(post["content"], style: TextStyle(
                        fontSize: 17,

                      ),),
                    ),

                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(formattedTimeStamp),
                  )
                ],
              ),



            ],
          )
      ),
    );

  }

  String GenerateConvoName (){
    List<String> NameList = [FirebaseAuth.instance.currentUser!.uid, partnerUID];
    NameList.sort(); //alphabetically
    return NameList[0] + "-" + NameList[1];
  }

  void scrollDown() {
    if (listScrollController.hasClients) {
      final position = listScrollController.position.maxScrollExtent;
      listScrollController.jumpTo(position);

    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(partnersName),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
                controller: listScrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _posts.length,
                itemBuilder: (BuildContext context, int index) {
                  String userUID = getUID();
                  scrollDown();
                  return (_posts[index]["author"] == userUID)? loadMessage(index) : loadPartnerMessage(index);
                },
              )

          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller : ChatController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                )
              ),
              IconButton(onPressed: sendMessage, icon: Icon(Icons.send)),
            ]
          )
        ]
      )
    );
  }
}
