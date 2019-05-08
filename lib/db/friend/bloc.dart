import 'package:flashmsg/db/friend/dao.dart';
import 'package:flashmsg/db/friend/model.dart';
import 'package:rxdart/rxdart.dart';

class FriendBloc {
  FriendBloc() {
    getFriends();
  }

  final _FriendController = BehaviorSubject<List<Friend>>();
  get friends => _FriendController.stream;

  dispose() {
    FriendDAO.db.kill();
    _FriendController.close();
  }

  getFriends() async {
    _FriendController.sink.add(await FriendDAO.db.getAllFriends());
  }

  updateFriend(String id, String last_msg_date, String last_msg) async {
    await FriendDAO.db.updateFriend(id, last_msg_date, last_msg);
    getFriends();
  }

  batchUpdateFriends() async {
    await FriendDAO.db.batchUpdateFriends();
    getFriends();
  }

  newFriend(id) async {
    await FriendDAO.db.newFriend(id);
    getFriends();
  }
}
