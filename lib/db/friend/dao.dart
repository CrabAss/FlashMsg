import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashmsg/db/friend/model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class FriendDAO {
  FriendDAO._();
  static final FriendDAO db = FriendDAO._();
  static Database _database;

  SharedPreferences prefs;

  Future<Database> get database async {
    if (_database != null) return _database;

    prefs = await SharedPreferences.getInstance();
    _database = await initDB(prefs.getString("id"));
//    batchUpdateFriends();
    return _database;
  }

  initDB(String myId) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "$myId.db");
    print("DB initialized at " + path);
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE Friend ("
          "id TEXT PRIMARY KEY,"
          "nickname TEXT,"
          "aboutMe TEXT,"
          "photoUrl TEXT,"
          "last_msg_date TEXT,"
          "last_msg TEXT"
          ")");
    });
  }

  kill() {
    print("db object killed");
    if (_database != null) {
      _database.close();
      _database = null;
    }
  }

  getLastMsg(String peerId) async {
    prefs = await SharedPreferences.getInstance();
    String groupChatId;
    String myId = prefs.getString('id') ?? '';
    if (myId.hashCode <= peerId.hashCode) {
      groupChatId = '$myId-$peerId';
    } else {
      groupChatId = '$peerId-$myId';
    }

    final QuerySnapshot LastMessageQuery = await Firestore.instance
        .collection('messages')
        .document(groupChatId)
        .collection(groupChatId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .getDocuments();
    final List<DocumentSnapshot> LastMessageDocuments =
        LastMessageQuery.documents;

    return LastMessageDocuments.length == 0 ? null : LastMessageDocuments[0];
  }

  newFriend(String peerId) async {
    final db = await database;

    QuerySnapshot UserQuery = await Firestore.instance
        .collection('users')
        .where('id', isEqualTo: peerId)
        .getDocuments();
    final DocumentSnapshot UserDocument = UserQuery.documents[0];
    final DocumentSnapshot LastMessageDocument = await getLastMsg(peerId);

    var lastMsgDate, lastMsg;

    if (LastMessageDocument == null) {
      lastMsgDate = DateTime.now().millisecondsSinceEpoch.toString();
      lastMsg = "Say \"Hi\" to your new friend!";
    } else {
      lastMsgDate = LastMessageDocument['timestamp'];
      lastMsg = LastMessageDocument['content'];
    }

    Friend newFriend = Friend(
        id: peerId,
        nickname: UserDocument['nickname'],
        aboutMe: UserDocument['aboutMe'],
        photoUrl: UserDocument['photoUrl'],
        lastMsgDate: lastMsgDate,
        lastMsg: lastMsg);

    var raw = await db.rawInsert(
        "INSERT Into Friend (id,nickname,aboutMe,photoUrl,last_msg_date,last_msg)"
        " VALUES (?,?,?,?,?,?)",
        [
          newFriend.id,
          newFriend.nickname,
          newFriend.aboutMe,
          newFriend.photoUrl,
          newFriend.lastMsgDate,
          newFriend.lastMsg
        ]);
    return newFriend;
  }

  updateFriend(String id, [String last_msg_date, String last_msg]) async {
    final db = await database;
    Friend friend = await getFriend(id);
    if (friend == null) {
      friend = await newFriend(id);
    }
    QuerySnapshot UserQuery = await Firestore.instance
        .collection('users')
        .where('id', isEqualTo: id)
        .getDocuments();
    final DocumentSnapshot UserDocument = UserQuery.documents[0];

    friend.nickname = UserDocument['nickname'];
    friend.aboutMe = UserDocument['aboutMe'];
    friend.photoUrl = UserDocument['photoUrl'];
    if (last_msg_date != null && last_msg != null) {
      friend.lastMsgDate = last_msg_date;
      friend.lastMsg = last_msg;
      print("Friend last message updated: " + last_msg);
    }
    var res = await db
        .update("Friend", friend.toJson(), where: "id = ?", whereArgs: [id]);
    return res;
  }

  batchUpdateFriends() async {
    print("friends batch updated");
    prefs = await SharedPreferences.getInstance();
    String myId = prefs.getString('id') ?? '';
    QuerySnapshot onlineFriendListQuery = await Firestore.instance
        .collection('users')
        .document(myId)
        .collection('friends')
        .getDocuments();
    List<DocumentSnapshot> onlineFriendList = onlineFriendListQuery.documents;
    for (final friend in onlineFriendList) {
      print("Online friend: " + friend['id']);
      final DocumentSnapshot LastMessageDocument =
          await getLastMsg(friend['id']);
      if (LastMessageDocument == null) {
        updateFriend(friend['id']);
      } else {
        updateFriend(friend['id'], LastMessageDocument['timestamp'],
            LastMessageDocument['type'] == 1 ? "[Image]" : LastMessageDocument['content']);
      }
    }
  }

  getFriend(String id) async {
    final db = await database;
    var res = await db.query("Friend", where: "id = ?", whereArgs: [id]);
    return res.isNotEmpty ? Friend.fromJson(res.first) : null;
  }

  Future<List<Friend>> getAllFriends() async {
    final db = await database;
    var res = await db.query("Friend",
        orderBy: "CAST(last_msg_date AS INTEGER) DESC");
    List<Friend> list =
        res.isNotEmpty ? res.map((c) => Friend.fromJson(c)).toList() : [];
    return list;
  }

//  deleteFriend(String id) async {
//    final db = await database;
//    return db.delete("Friend", where: "id = ?", whereArgs: [id]);
//  }
//
//  deleteAll() async {
//    final db = await database;
//    db.rawDelete("Delete * from Friend");
//  }
}
