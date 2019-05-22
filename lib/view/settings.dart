import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flashmsg/config/const.dart';
import 'package:flashmsg/state/account.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  TextEditingController controllerNickname;
  TextEditingController controllerAboutMe;

  SharedPreferences prefs;
  MyAccount myAccount;

  bool isLoading = false;
  File avatarImageFile;

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((SharedPreferences value) => prefs = value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    myAccount = Provider.of<MyAccount>(context);
    controllerNickname = TextEditingController(text: myAccount.nickname);
    controllerAboutMe = TextEditingController(text: myAccount.aboutMe);
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
    String fileName = myAccount.id;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(avatarImageFile);
    StorageTaskSnapshot storageTaskSnapshot;
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
          myAccount.update(photoUrl: downloadUrl);
          Firestore.instance.collection('users').document(myAccount.id).updateData({
            'nickname': myAccount.nickname,
            'aboutMe': myAccount.aboutMe,
            'photoUrl': myAccount.photoUrl
          }).then((data) async {
            await prefs.setString('photoUrl', myAccount.photoUrl);
            setState(() => isLoading = false);
            Fluttertoast.showToast(msg: "Upload success");
          }).catchError((err) {
            setState(() => isLoading = false);
            Fluttertoast.showToast(msg: err.toString());
          });
        }, onError: (err) {
          setState(() => isLoading = false);
          Fluttertoast.showToast(msg: 'This file is not an image');
        });
      } else {
        setState(() => isLoading = false);
        Fluttertoast.showToast(msg: 'This file is not an image');
      }
    }, onError: (err) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  Future<bool> handleUpdateData() async {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() => isLoading = true);

    try {
      await Firestore.instance.collection('users').document(myAccount.id).updateData({
        'nickname': myAccount.nickname,
        'aboutMe': myAccount.aboutMe,
        'photoUrl': myAccount.photoUrl
      });
      await prefs.setString('nickname', myAccount.nickname);
      await prefs.setString('aboutMe', myAccount.aboutMe);
      await prefs.setString('photoUrl', myAccount.photoUrl);

      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: "Update success");
      return Future.value(true);
    } catch (err) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: err.toString());
      return Future.value(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
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
                                    ? (myAccount.photoUrl != ''
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
                                              imageUrl: myAccount.photoUrl,
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
                                    contentPadding: EdgeInsets.all(5.0),
                                    hintStyle: TextStyle(color: greyColor),
                                  ),
                                  controller: controllerNickname,
                                  onChanged: (value) {
                                    myAccount.update(nickname: value);
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
                                    myAccount.update(aboutMe: value);
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
              ],
            ),
          ),

          // Loading
          buildLoading(isLoading),
        ],
      ), onWillPop: handleUpdateData,
    );
  }
}
