import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashmsg/config/const.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddFriendScreen extends StatefulWidget {
  final String myId;

  const AddFriendScreen({Key key, this.myId}) : super(key: key);

  @override
  AddFriendScreenState createState() => AddFriendScreenState(myIdURI: uriPrefix + myId, myId: myId);
}

class AddFriendScreenState extends State<AddFriendScreen> {
  String barcode = "";
  SharedPreferences prefs;

  GlobalKey globalKey = GlobalKey();
  String myIdURI;
  String myId;

  bool isLoading = false;

  AddFriendScreenState({Key key, @required this.myIdURI, @required this.myId});

  Future<AsyncSnapshot> getMyData() async {
    prefs = await SharedPreferences.getInstance();
    Map result = Map();
    result['nickname'] = prefs.getString('nickname') ?? '';
    result['aboutMe'] = prefs.getString('aboutMe') ?? '';
    result['photoUrl'] = prefs.getString('photoUrl') ?? '';
    return AsyncSnapshot.withData(ConnectionState.done, result);
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
                              new BoxShadow(blurRadius: 8, color: greyColor)
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
                                    data: myIdURI,
                                    size: 300,
                                    onError: (ex) {
                                      print("[QR] ERROR - $ex");
                                      setState(() {
                                        this.barcode =
                                            "Error! Maybe your input value is too long?";
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: 300,
                                  padding: EdgeInsets.all(8),
                                  child: FutureBuilder<AsyncSnapshot>(
                                    future: getMyData(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot snapshot) {
                                      if (!snapshot.hasData) {
                                        return Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    themeColor),
                                          ),
                                        );
                                      } else {
                                        return mePreview(snapshot.data.data);
                                      }
                                    },
                                  ),
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
            Positioned(
              child: isLoading
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(themeColor)),
                      ),
                      color: Colors.white.withOpacity(0.8),
                    )
                  : Container(),
            )
          ],
        ));
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() {
        isLoading = true;
        findFriend(barcode);
        return this.barcode = barcode;
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          _showAlertDialog('The user did not grant the camera permission!');
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

  Widget friendPreview(DocumentSnapshot document) {
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
            imageUrl: document['photoUrl'],
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
                    '${document['nickname']}',
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
                      '${document['aboutMe']}',
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w400),
                    ),
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                  ),
                  visible: document['aboutMe'] == null ? false : true,
                )
              ],
            ),
            margin: EdgeInsets.only(left: 10.0),
          ),
        ),
      ],
    );
  }

  Widget mePreview(Map document) {
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
            imageUrl: document['photoUrl'],
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
                    '${document['nickname']}',
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
                      '${document['aboutMe']}',
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w400),
                    ),
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                  ),
                  visible: document['aboutMe'] == "" ? false : true,
                )
              ],
            ),
            margin: EdgeInsets.only(left: 10.0),
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(DocumentSnapshot document) {
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
                child: friendPreview(document),
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
                  addNewFriend(document);
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
    String userId;
    if (userURI.startsWith(uriPrefix)) {
      userId = userURI.substring(uriPrefix.length);
      QuerySnapshot result = await Firestore.instance
          .collection('users')
          .document(myId)
          .collection('friends')
          .where('id', isEqualTo: userId)
          .getDocuments();
      List<DocumentSnapshot> documents = result.documents;
      if (documents.length > 0) {
        setState(() {
          isLoading = false;
          _showAlertDialog("This user is your friend already.");
        });
        return;
      }
      result = await Firestore.instance
          .collection('users')
          .where('id', isEqualTo: userId)
          .getDocuments();
      documents = result.documents;
      if (documents.length == 0) {
        setState(() {
          isLoading = false;
          _showAlertDialog("This user does not exist in FlashMsg.");
        });
        return;
      }
      setState(() {
        isLoading = false;
        _showConfirmationDialog(documents[0]);
      });
    } else {
      setState(() {
        isLoading = false;
        _showAlertDialog("This QR code is not generated by FlashMsg.");
      });
    }
  }

  void addNewFriend(DocumentSnapshot document) async {
    prefs = await SharedPreferences.getInstance();
    Firestore.instance
        .collection('users')
        .document(myId)
        .collection('friends')
        .document(document['id'])
        .setData({
      'id': document['id'],
    });
    Firestore.instance
        .collection('users')
        .document(document['id'])
        .collection('friends')
        .document(myId)
        .setData({
      'id': myId,
    });
    setState(() {
      isLoading = false;
      Fluttertoast.showToast(msg: "Added successfully!");
    });
  }
}
