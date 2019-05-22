import 'dart:ui';

import 'package:flutter/material.dart';

final themeColor = Colors.teal;
final primaryColor = Color(0xff203152);
final whiteColor = Colors.white;
final greyColor = Color(0xffaeaeae);
final greyColor2 = Color(0xffE8E8E8);

final Duration doubleTapInterval = Duration(seconds: 2);

final String appName = "FlashMsg";
final String userURIPrefix = "flashmsg://user/";

final String newFriendMsg = "Say \"Hi\" to your new friend!";
final String doubleTapToQuitMsg = "Tap \"Back\" again to quit...";

Widget buildLoading(bool isLoading) {
  return Positioned(
    child: isLoading
        ? Container(
            child: Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
            ),
            color: Colors.white.withOpacity(0.8),
          )
        : Container(),
  );
}
