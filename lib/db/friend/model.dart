// To parse this JSON data, do
//
//     final friend = friendFromJson(jsonString);

import 'dart:convert';

Friend friendFromJson(String str) => Friend.fromJson(json.decode(str));

String friendToJson(Friend data) => json.encode(data.toJson());

class Friend {
  String id;
  String nickname;
  String aboutMe;
  String photoUrl;
  String lastMsgDate;
  String lastMsg;

  Friend({
    this.id,
    this.nickname,
    this.aboutMe,
    this.photoUrl,
    this.lastMsgDate,
    this.lastMsg,
  });

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    id: json["id"],
    nickname: json["nickname"],
    aboutMe: json["aboutMe"],
    photoUrl: json["photoUrl"],
    lastMsgDate: json["last_msg_date"],
    lastMsg: json["last_msg"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nickname": nickname,
    "aboutMe": aboutMe,
    "photoUrl": photoUrl,
    "last_msg_date": lastMsgDate,
    "last_msg": lastMsg,
  };
}
