import 'package:flashmsg/config/const.dart';
import 'package:flashmsg/view/AppViews.dart';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  title: appName,
  home: LoginScreen(),
  theme: ThemeData(
    primaryColor: themeColor,
  ),
  debugShowCheckedModeBanner: false,
));
