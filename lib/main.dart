import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flashmsg/chat.dart';
import 'package:flashmsg/const.dart';
import 'package:flashmsg/db/friend/bloc.dart';
import 'package:flashmsg/db/friend/model.dart';
import 'package:flashmsg/login.dart';
import 'package:flashmsg/qr_scan.dart';
import 'package:flashmsg/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MainScreen extends StatefulWidget {
  final String currentUserId;

  MainScreen({Key key, @required this.currentUserId}) : super(key: key);

  @override
  State createState() => MainScreenState(currentUserId: currentUserId);
}

class MainScreenState extends State<MainScreen> {
  MainScreenState({Key key, @required this.currentUserId});

  final String currentUserId;
  final friendBloc = FriendBloc();

  @override
  void dispose() {
    friendBloc.dispose();
    super.dispose();
  }

  DateTime currentBackPressTime = DateTime.now();

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool isLoading = false;
  bool isSigningOut = false;

  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    firebaseCloudMessaging_Listeners();
    setState(() {
      friendBloc.batchUpdateFriends();
    });
  }

  void firebaseCloudMessaging_Listeners() async {
    if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.getToken().then((token) {
      print(token);
      Firestore.instance
          .collection('fcm_tokens')
          .document(currentUserId)
          .setData({'token': token});
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
        handleMessage(message);
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
        handleMessage(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
        handleMessage(message);
      },
    );
  }

  void handleMessage(Map<String, dynamic> message) {
    if (message['data']['type'] == "newMessage") {
      handleNewMessage(message);
    } else if (message['data']['type'] == "newFriend") {
      handleNewFriend(message);
    }
  }

  void handleNewMessage(Map<String, dynamic> message) {
    friendBloc.updateFriend(message["data"]["senderId"],
        message["data"]["timestamp"], message["notification"]["body"]);
  }

  void handleNewFriend(Map<String, dynamic> message) {
    friendBloc.newFriend(message['data']['friendId']);
  }

  void iOS_Permission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

  Future<bool> onBackPress() {
    DateTime now = DateTime.now();
    if (now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: "Tap \"Back\" again to quit...");
      return Future.value(false);
    }
    exit(0);
//    return Future.value(true);
  }

  Widget buildItem(BuildContext context, Friend document) {
    if (document.id == currentUserId) {
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: CachedNetworkImage(
                  placeholder: (context, url) => Container(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.0,
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                        width: 50.0,
                        height: 50.0,
                        padding: EdgeInsets.all(15.0),
                      ),
                  imageUrl: document.photoUrl,
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '${document.nickname}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              DateFormat('dd MMM kk:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(document.lastMsgDate))),
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12),
                            )
                          ],
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                      ),
                      Container(
                        child: Text(
                          '${document.lastMsg}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w400,
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(left: 10.0),
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => Chat(
                          peerId: document.id,
                          peerNickname: document.nickname ?? "Unknown",
                          peerAvatar: document.photoUrl,
                          friendBloc: friendBloc,
                        )));
          },
//          color: greyColor2,
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
//          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
    }
  }

  final GoogleSignIn googleSignIn = GoogleSignIn();

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(
          context, CupertinoPageRoute(builder: (context) => Settings()));
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
      isSigningOut = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
/*    try {
      if (isSigningOut == false)
        bloc.batchUpdateFriends();
    } catch (e) {}*/
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FlashMsg',
          style: TextStyle(color: whiteColor),
        ),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => ScanScreen(currentUserId)),
              );
            },
          ),
          PopupMenuButton<Choice>(
            onSelected: onItemMenuPress,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                    value: choice,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          choice.icon,
                          color: primaryColor,
                        ),
                        Container(
                          width: 10.0,
                        ),
                        Text(
                          choice.title,
                          style: TextStyle(color: primaryColor),
                        ),
                      ],
                    ));
              }).toList();
            },
          ),
        ],
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List
            Container(
              child: StreamBuilder(
                stream: friendBloc.friends,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      ),
                    );
                  } else {
                    return RefreshIndicator(
                      onRefresh: () => friendBloc.batchUpdateFriends(),
                      child: ListView.separated(
                        padding: EdgeInsets.all(4.0),
                        itemBuilder: (context, index) =>
                            buildItem(context, snapshot.data[index]),
                        itemCount: snapshot.data.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            Divider(
                              color: greyColor2,
                              indent: 82,
                              height: 1,
                            ),
                      ),
                    );
                  }
                },
              ),
            ),

            // Loading
            Positioned(
              child: isLoading
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(themeColor)),
                      ),
                      color: Colors.white.withOpacity(0.8),
                    )
                  : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }
}

class Choice {
  final String title;
  final IconData icon;

  const Choice({this.title, this.icon});
}
