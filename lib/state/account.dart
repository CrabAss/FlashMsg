import 'package:flutter/foundation.dart';

class Account with ChangeNotifier {
  String _id;
  String _nickname;
  String _aboutMe;
  String _photoUrl;

  String get id => _id;
  String get nickname => _nickname;
  String get aboutMe => _aboutMe;
  String get photoUrl => _photoUrl;

  void update({String id, String nickname, String aboutMe, String photoUrl}) {
    if (id != null) _id = id;
    if (nickname != null) _nickname = nickname;
    if (aboutMe != null) _aboutMe = aboutMe;
    if (photoUrl != null) _photoUrl = photoUrl;
    notifyListeners();
  }
}

class MyAccount extends Account {}

class PeerAccount extends Account {
  PeerAccount({@required String id, String nickname, String aboutMe, String photoUrl}) {
    if (id != null) _id = id;
    if (nickname != null) _nickname = nickname;
    if (aboutMe != null) _aboutMe = aboutMe;
    if (photoUrl != null) _photoUrl = photoUrl;
    notifyListeners();
  }
}