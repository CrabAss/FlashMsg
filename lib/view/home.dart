import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flashmsg/config/const.dart';
import 'package:flashmsg/controller/fcm.dart';
import 'package:flashmsg/db/friend/bloc.dart';
import 'package:flashmsg/db/friend/model.dart';
import 'package:flashmsg/state/account.dart';
import 'package:flashmsg/view/add_friend.dart';
import 'package:flashmsg/view/chat.dart';
import 'package:flashmsg/view/login.dart';
import 'package:flashmsg/view/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  State createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  HomeScreenState({Key key});

  final FriendBloc friendBloc = FriendBloc();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  MyAccount myAccount;
  FCMController fcmController;
  DateTime currentBackPressTime = DateTime.now().subtract(doubleTapInterval);

  bool isLoading = false;

  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    myAccount = Provider.of<MyAccount>(context);
    fcmController = FCMController(myAccount.id, friendBloc);

    setState(() {
      friendBloc.batchUpdateFriends();
    });
  }

  @override
  void dispose() {
    friendBloc.dispose();
    super.dispose();
  }

  Future<bool> onBackPress() {
    DateTime now = DateTime.now();
    if (now.difference(currentBackPressTime) >= doubleTapInterval) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: doubleTapToQuitMsg);
      return Future.value(false);
    } else return Future.value(true);
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(
          context, CupertinoPageRoute(builder: (context) => Settings()));
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() => isLoading = true);

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() => isLoading = false);

    Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false);
  }

  Widget buildItem(BuildContext context, Friend friendEntry) {
    if (friendEntry.id == myAccount.id) {
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
                  imageUrl: friendEntry.photoUrl,
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
                              '${friendEntry.nickname}',
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
                                      int.parse(friendEntry.lastMsgDate))),
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
                          '${friendEntry.lastMsg}',
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
                    builder: (context) => MultiProvider(
                            providers: [
                              ChangeNotifierProvider(
                                  builder: (_) => PeerAccount(
                                        id: friendEntry.id,
                                        nickname: friendEntry.nickname ?? "Unknown",
                                        photoUrl: friendEntry.photoUrl,
                                        aboutMe: friendEntry.aboutMe,
                                      )),
                              Provider<FriendBloc>.value(value: friendBloc),
                            ],
                            child: Chat())));
          },
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FlashMsg'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => AddFriendScreen()),
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

            buildLoading(isLoading),
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
