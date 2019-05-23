import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flashmsg/db/friend/bloc.dart';

class FCMController {

  final String _myId;
  final FriendBloc _friendBloc;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  static FCMController _singleton;

  factory FCMController(myId, friendBloc) {
    if (_singleton == null) {
      _singleton = FCMController._internal(myId, friendBloc);
    }
    return _singleton;
  }

  FCMController._internal(this._myId, this._friendBloc) {
    initFCMListeners();
  }

  void dispose() {
    _singleton = null;
  }

  void updateToken() {
    _firebaseMessaging.getToken().then((token) {
      print("FCM controller initialized at usedId == $_myId with token == $token");
      Firestore.instance
          .collection('fcm_tokens')
          .document(_myId)
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
    _friendBloc.updateFriend(message["data"]["senderId"],
        message["data"]["timestamp"], message["notification"]["body"]);
  }

  void handleNewFriend(Map<String, dynamic> message) {
    _friendBloc.newFriend(message['data']['friendId']);
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