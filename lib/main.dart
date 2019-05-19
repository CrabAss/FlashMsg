import 'package:flashmsg/config/const.dart';
import 'package:flashmsg/state/account.dart';
import 'package:flashmsg/view/AppViews.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(FlashMsg());

class FlashMsg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (_) => MyAccount()),
      ],
      child: MaterialApp(
        title: appName,
        home: LoginScreen(),
        theme: ThemeData(
          primaryColor: themeColor,
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
