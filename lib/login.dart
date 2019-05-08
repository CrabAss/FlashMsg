import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flashmsg/const.dart';
import 'package:flashmsg/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlashMsg',
      home: LoginScreen(),
      theme: ThemeData(
        primaryColor: themeColor,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) =>
                MainScreen(currentUserId: prefs.getString('id'))),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }

  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    FirebaseUser firebaseUser =
        await firebaseAuth.signInWithCredential(credential);

    if (firebaseUser != null) {
      // Check is already sign up
      final QuerySnapshot result = await Firestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if (documents.length == 0) {
        // Update data to server if new user
        Firestore.instance
            .collection('users')
            .document(firebaseUser.uid)
            .setData({
          'nickname': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoUrl,
          'id': firebaseUser.uid
        });

        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoUrl);
      } else {
        // Write data to local
        await prefs.setString('id', documents[0]['id']);
        await prefs.setString('nickname', documents[0]['nickname']);
        await prefs.setString('photoUrl', documents[0]['photoUrl']);
        await prefs.setString('aboutMe', documents[0]['aboutMe']);
      }
      print("pref already set: " + prefs.getString('id'));
      Fluttertoast.showToast(
          msg: "Welcome, " + prefs.getString('nickname') + "!");
      this.setState(() {
        isLoading = false;
      });

      Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => MainScreen(
                  currentUserId: firebaseUser.uid,
                )),
      );
    } else {
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(color: whiteColor),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: themeColor),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Icon(
                          Icons.forum,
                          size: 128,
                          color: whiteColor,
                        ),
                      ),
                      Text(
                        "Welcome to",
                        style: TextStyle(color: whiteColor, fontSize: 24),
                      ),
                      Text(
                        "FlashMsg",
                        style: TextStyle(
                            color: whiteColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 160,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: GoogleSignInButton(
                      onPressed: handleSignIn,
                      darkMode: true,
                    ),
                  ),

                  // Loading
                  Positioned(
                    child: isLoading
                        ? Container(
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(themeColor),
                              ),
                            ),
                            color: Colors.white.withOpacity(0.8),
                          )
                        : Container(),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
