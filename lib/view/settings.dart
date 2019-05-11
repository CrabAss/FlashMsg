import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flashmsg/config/const.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(
          'Settings',
          style: TextStyle(color: whiteColor),
        ),
      ),
      body: new SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => new SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  TextEditingController controllerNickname;
  TextEditingController controllerAboutMe;

  SharedPreferences prefs;

  String id = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';

  bool isLoading = false;
  File avatarImageFile;

  final FocusNode focusNodeNickname = new FocusNode();
  final FocusNode focusNodeAboutMe = new FocusNode();

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    nickname = prefs.getString('nickname') ?? '';
    aboutMe = prefs.getString('aboutMe') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';

    controllerNickname = new TextEditingController(text: nickname);
    controllerAboutMe = new TextEditingController(text: aboutMe);

    // Force refresh input
    setState(() {});
  }

  Future getImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
    }
    uploadFile();
  }

  Future uploadFile() async {
    String fileName = id;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(avatarImageFile);
    StorageTaskSnapshot storageTaskSnapshot;
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
          photoUrl = downloadUrl;
          Firestore.instance.collection('users').document(id).updateData({
            'nickname': nickname,
            'aboutMe': aboutMe,
            'photoUrl': photoUrl
          }).then((data) async {
            await prefs.setString('photoUrl', photoUrl);
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: "Upload success");
          }).catchError((err) {
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: err.toString());
          });
        }, onError: (err) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: 'This file is not an image');
        });
      } else {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: 'This file is not an image');
      }
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
    });

    Firestore.instance.collection('users').document(id).updateData({
      'nickname': nickname,
      'aboutMe': aboutMe,
      'photoUrl': photoUrl
    }).then((data) async {
      await prefs.setString('nickname', nickname);
      await prefs.setString('aboutMe', aboutMe);
      await prefs.setString('photoUrl', photoUrl);

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: "Update success");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      // Avatar
                      Container(
                        child: Center(
                          child: Stack(
                            children: <Widget>[
                              (avatarImageFile == null)
                                  ? (photoUrl != ''
                                      ? Material(
                                          child: CachedNetworkImage(
                                            placeholder: (context, url) =>
                                                Container(
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.0,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(themeColor),
                                                  ),
                                                  width: 90.0,
                                                  height: 90.0,
                                                  padding: EdgeInsets.all(20.0),
                                                ),
                                            imageUrl: photoUrl,
                                            width: 90.0,
                                            height: 90.0,
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(45.0)),
                                          clipBehavior: Clip.hardEdge,
                                        )
                                      : Icon(
                                          Icons.account_circle,
                                          size: 90.0,
                                          color: greyColor,
                                        ))
                                  : Material(
                                      child: Image.file(
                                        avatarImageFile,
                                        width: 90.0,
                                        height: 90.0,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(45.0)),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                              IconButton(
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: primaryColor.withOpacity(0.5),
                                ),
                                onPressed: getImage,
                                padding: EdgeInsets.all(30.0),
                                splashColor: Colors.transparent,
                                highlightColor: greyColor,
                                iconSize: 30.0,
                              ),
                            ],
                          ),
                        ),
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 32.0),
                      ),

                      // Input
                      Column(
                        children: <Widget>[
                          // Username
                          Container(
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(primaryColor: primaryColor),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Nickname',
                                  hintText: 'Sweetie',
                                  contentPadding: new EdgeInsets.all(5.0),
                                  hintStyle: TextStyle(color: greyColor),
                                ),
                                controller: controllerNickname,
                                onChanged: (value) {
                                  nickname = value;
                                },
                                focusNode: focusNodeNickname,
                              ),
                            ),
                            margin: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 30.0),
                          ),

                          // About me
                          Container(
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(primaryColor: primaryColor),
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  hintText: 'Fun, like travel and play PES...',
                                  contentPadding: EdgeInsets.all(5.0),
                                  hintStyle: TextStyle(color: greyColor),
                                ),
                                controller: controllerAboutMe,
                                onChanged: (value) {
                                  aboutMe = value;
                                },
                                focusNode: focusNodeAboutMe,
                              ),
                            ),
                            margin: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 30.0),
                          ),
                        ],
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ],
                  ),
                ),
              ),

              // Button
              Container(
                child: RaisedButton(
                  onPressed: handleUpdateData,
                  child: Text(
                    'UPDATE',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  color: themeColor,
                  textColor: Colors.white,
                  splashColor: themeColor.shade200,
                  padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                ),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ],
          ),
//          padding: EdgeInsets.only(left: 15.0, right: 15.0),
        ),

        // Loading
        Positioned(
          child: isLoading
              ? Container(
                  child: Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
                  ),
                  color: Colors.white.withOpacity(0.8),
                )
              : Container(),
        ),
      ],
    );
  }
}
