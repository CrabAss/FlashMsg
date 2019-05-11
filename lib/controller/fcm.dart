import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flashmsg/db/friend/bloc.dart';

class FCMController {
  final String myId;
  final FriendBloc friendBloc;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  FCMController(this.myId, this.friendBloc) {
    initFCMListeners();
  }

  void updateToken() {
    _firebaseMessaging.getToken().then((token) {
      print(token);
      Firestore.instance
          .collection('fcm_tokens')
          .document(myId)
          .setData({'token': token});
    });
  }

  void initFCMListeners() async {
    if (Platform.isIOS) iosPermission();

    updateToken();

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

  void iosPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }

}