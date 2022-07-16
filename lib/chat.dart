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

  String partnersName = "";
  ScrollController listScrollController = ScrollController();

  _ChatState()
  {
    //generate convo name
    convoName = generateConvoName(partnerUID);

    //get user names
    getUsername();

    //get chat log
    getChatLogs();

    //update chat logs whenever firebase changes
    FirebaseDatabase.instance.ref().child("userChat/" + convoName).limitToLast(1).onChildAdded.listen((event) {
      getChatLogs();
    });
  }

  //grabs a list of all chat logs for this conversation
  Future <void> getChatLogs () async {
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

  //gets the partner's username
  Future <void> getUsername() async {
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

  //adds a message to the convo log, with a timestamp
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

  //creates a widget containing information about a post, including content and timestamp.
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

  //creates a widget containing information about a partner's post, including content and timestamp.
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

  //automatically scrolls down to the bottom.
  //this is called when a post is made.
  void scrollDown() {
    if (listScrollController.hasClients) {
      final position = listScrollController.position.maxScrollExtent;
      listScrollController.jumpTo(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 10,
            child: Container(
                color: Color(0xff7986cb),
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: Text(
                      partnersName,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      ),
                  ),
                )
            ),
          ),
          Expanded (
              flex: 90,
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
