import 'dart:async';

import 'package:flashmsg/database.dart';
import 'package:flashmsg/friend_model.dart';

class FriendsBloc {
  FriendsBloc() {
    getFriends();
  }

  final _FriendController = StreamController<List<Friend>>.broadcast();
  get friends => _FriendController.stream;

  dispose() {
    DBProvider.db.kill();
    _FriendController.close();
  }

  getFriends() async {
    _FriendController.sink.add(await DBProvider.db.getAllFriends());
  }

  updateFriend(String id, String last_msg_date, String last_msg) async {
    await DBProvider.db.updateFriend(id, last_msg_date, last_msg);
    getFriends();
  }

  batchUpdateFriends() async {
    await DBProvider.db.batchUpdateFriends();
    getFriends();
  }

  newFriend(id) async {
    await DBProvider.db.newFriend(id);
    getFriends();
  }
}