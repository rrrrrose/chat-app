import 'package:flutter/material.dart';

import 'Post.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int currentPageIndex = 0;
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
        Container(
          child: Column(
              children: [

                Expanded(
                    flex: 25,
                    child: Container(
                      color: Colors.amberAccent,
                      child: Padding(
                        padding: const EdgeInsets.only(top:10),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                  width: 100,
                                  height: 100,
                                  child: Image.network('https://picsum.photos/250?image=9')
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row (
                                  children: [
                                    Text(
                                        'NAME',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 55)
                                        ),
                                    Icon(Icons.check)
                                  ]
                                ),
                                Text(
                                    'DESCRIPTION',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 36)
                                ),
                              ]
                            )
                          ]

                        ),
                      ),
                    )
                ),
                Expanded(
                  flex: 75,
                  child: ListView(
                    children: [
                      Container(
                        child: Column(
                          children: [
                            Text("Date"),
                            Text("Texttttttttt")
                          ]
                        )
                      )
                    ]
                  )
                ),
                ElevatedButton(onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Post()),
                  );
                }, child: Text("Post"))
              ],
          ),
        ),
        Container(
          color: Colors.green,
          alignment: Alignment.center,
          child: const Text('Page 2'),
        ),
      ][currentPageIndex],
    );

  }
}
