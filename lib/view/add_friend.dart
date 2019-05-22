import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashmsg/config/const.dart';
import 'package:flashmsg/state/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AddFriendScreen extends StatefulWidget {

  const AddFriendScreen({Key key}) : super(key: key);

  @override
  AddFriendScreenState createState() => AddFriendScreenState();
}

class AddFriendScreenState extends State<AddFriendScreen> {
  MyAccount myAccount;

  GlobalKey globalKey = GlobalKey();

  bool isLoading = false;

  AddFriendScreenState({Key key});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    myAccount = Provider.of<MyAccount>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Add new friends'),
        ),
        body: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(color: greyColor2),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(blurRadius: 8, color: greyColor)
                            ],
                            borderRadius:
                                BorderRadius.all(Radius.circular(4.0)),
                            color: whiteColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                RepaintBoundary(
                                  key: globalKey,
                                  child: QrImage(
                                    data: userURIPrefix + myAccount.id,
                                    size: 300,
                                    onError: (e) {
                                      setState(() => _showAlertDialog('Unknown error: $e'));
                                    },
                                  ),
                                ),
                                Container(
                                  width: 300,
                                  padding: EdgeInsets.all(8),
                                  child: mePreview(),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: RaisedButton(
                        child: const Text(
                          'SCAN QR CODE',
                          style: TextStyle(fontSize: 16),
                        ),
                        color: themeColor,
                        textColor: Colors.white,
                        splashColor: themeColor.shade200,
                        onPressed: scan,
                        padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            buildLoading(isLoading),
          ],
        ));
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() {
        isLoading = true;
        findFriend(barcode);
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          _showAlertDialog('Sorry. We failed to scan because you did not grant the camera permission.');
        });
      } else {
        setState(() => _showAlertDialog('Unknown error: $e'));
      }
    } on FormatException {
      // setState(() => _showDialog('You have not scanned anything!'));  // unnecessary
    } catch (e) {
      setState(() => _showAlertDialog('Unknown error: $e'));
    }
  }

  void _showAlertDialog(String errorText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Oops!"),
          content: Text(errorText),
          actions: <Widget>[
            FlatButton(
              child: Text("CLOSE"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget friendPreview(DocumentSnapshot userProfile) {
    return Row(
      children: <Widget>[
        Material(
          child: CachedNetworkImage(
            placeholder: (context, url) => Container(
                  child: CircularProgressIndicator(
                    strokeWidth: 1.0,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                  width: 50.0,
                  height: 50.0,
                  padding: EdgeInsets.all(15.0),
                ),
            imageUrl: userProfile['photoUrl'],
            width: 50.0,
            height: 50.0,
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
          clipBehavior: Clip.hardEdge,
        ),
        Flexible(
          child: Container(
            child: Column(
              children: <Widget>[
                Container(
                  child: Text(
                    '${userProfile['nickname']}',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                ),
                Visibility(
                  child: Container(
                    child: Text(
                      '${userProfile['aboutMe']}',
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w400),
                    ),
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                  ),
                  visible: userProfile['aboutMe'] == null ? false : true,
                )
              ],
            ),
            margin: EdgeInsets.only(left: 10.0),
          ),
        ),
      ],
    );
  }

  Widget mePreview() {
    return Row(
      children: <Widget>[
        Material(
          child: CachedNetworkImage(
            placeholder: (context, url) => Container(
                  child: CircularProgressIndicator(
                    strokeWidth: 1.0,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                  width: 50.0,
                  height: 50.0,
                  padding: EdgeInsets.all(15.0),
                ),
            imageUrl: myAccount.photoUrl,
            width: 50.0,
            height: 50.0,
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
          clipBehavior: Clip.hardEdge,
        ),
        Flexible(
          child: Container(
            child: Column(
              children: <Widget>[
                Container(
                  child: Text(myAccount.nickname,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                ),
                Visibility(
                  child: Container(
                    child: Text(myAccount.aboutMe,
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w400),
                    ),
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                  ),
                  visible: myAccount.aboutMe == "" ? false : true,
                )
              ],
            ),
            margin: EdgeInsets.only(left: 10.0),
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(DocumentSnapshot userProfile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Friend found!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[Text("Is this the friend you want to add?")],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 25.0),
                child: friendPreview(userProfile),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("CANCEL"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("CONFIRM"),
              onPressed: () {
                setState(() {
                  isLoading = true;
                  addNewFriend(userProfile);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void findFriend(String userURI) async {
    if (!userURI.startsWith(userURIPrefix)) {
      setState(() {
        isLoading = false;
        _showAlertDialog("This QR code is not generated by FlashMsg.");
      });
    } else {
      String userId = userURI.substring(userURIPrefix.length);
      QuerySnapshot result = await Firestore.instance
          .collection('users').document(myAccount.id)
          .collection('friends').where('id', isEqualTo: userId)
          .getDocuments();
      if (result.documents.length > 0) {
        setState(() {
          isLoading = false;
          _showAlertDialog("This user is your friend already.");
        });
      } else {
        result = await Firestore.instance
            .collection('users').where('id', isEqualTo: userId)
            .getDocuments();
        if (result.documents.length == 0) {
          setState(() {
            isLoading = false;
            _showAlertDialog("This user does not exist in FlashMsg.");
          });
        } else {
          setState(() {
            isLoading = false;
            _showConfirmationDialog(result.documents[0]);
          });
        }
      }
    }
  }

  void addNewFriend(DocumentSnapshot userProfile) async {
    Firestore.instance
        .collection('users')
        .document(myAccount.id)
        .collection('friends')
        .document(userProfile['id'])
        .setData({
      'id': userProfile['id'],
    });
    Firestore.instance
        .collection('users')
        .document(userProfile['id'])
        .collection('friends')
        .document(myAccount.id)
        .setData({
      'id': myAccount.id,
    });
    setState(() {
      isLoading = false;
      Fluttertoast.showToast(msg: "Added successfully!");
    });
  }
}
