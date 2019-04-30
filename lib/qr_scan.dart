import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashmsg/const.dart';
import 'package:shared_preferences/shared_preferences.dart';


final String URI_PREFIX = "flashmsg://user/";
final String NEW_FRIEND_MSG = "Say \"Hi\" to your new friend!";

class ScanScreen extends StatefulWidget {
  String myIdURI;
  String myId;
  ScanScreen (@required String myId) {
    this.myIdURI = URI_PREFIX + myId;
    this.myId = myId;
  }

  @override
  _ScanState createState() => _ScanState(myIdURI: myIdURI, myId: myId);
}

class _ScanState extends State<ScanScreen> {
  String barcode = "";
  SharedPreferences prefs;

  GlobalKey globalKey = GlobalKey();
  String myIdURI;
  String myId;

  _ScanState({Key key, @required this.myIdURI, @required this.myId});

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Add new friends'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: RepaintBoundary(
                  key: globalKey,
                  child: QrImage(
                    data: myIdURI,
                    size: 300,
                    onError: (ex) {
                      print("[QR] ERROR - $ex");
                      setState((){
                        this.barcode = "Error! Maybe your input value is too long?";
                      });
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: RaisedButton(
                    color: themeColor,
                    textColor: Colors.white,
                    splashColor: themeColor.shade100,
                    onPressed: scan,
                    child: const Text('SCAN QR CODE')
                ),
              ),
              Padding(  // FOR TESTING PURPOSE ONLY
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(barcode, textAlign: TextAlign.center,),
              ),
            ],
          ),
        ));
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() {
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
    } on FormatException{
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
                children: <Widget>[
                  Text(
                    "Is this the friend you want to add?"
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 25.0),
                child: Row(
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
                                  color: primaryColor,
                                  fontSize: 18,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                            ),
                            Visibility(
                              child: Container(
                                child: Text(
                                  '${document['aboutMe']}',
                                  style: TextStyle(color: Colors.black45),
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
                ),
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
                addNewFriend(document);
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
    if (userURI.startsWith(URI_PREFIX)) {
      userId = userURI.substring(URI_PREFIX.length);
      QuerySnapshot result = await Firestore.instance
          .collection('users')
          .document(myId)
          .collection('friends')
          .where('id', isEqualTo: userId).getDocuments();
      List<DocumentSnapshot> documents = result.documents;
      if (documents.length > 0) {
        _showAlertDialog("This user is your friend already.");
        return;
      }
      result = await Firestore.instance
          .collection('users').where('id', isEqualTo: userId).getDocuments();
      documents = result.documents;
      if (documents.length == 0) {
        _showAlertDialog("This user does not exist in FlashMsg.");
        return;
      }
      _showConfirmationDialog(documents[0]);
    } else {
      _showAlertDialog("This QR code is not generated by FlashMsg.");
    }
  }

  void addNewFriend(DocumentSnapshot document) async {
    prefs = await SharedPreferences.getInstance();
    // DATABASE WRITE
    var now = DateTime.now().millisecondsSinceEpoch.toString();
    Firestore.instance
        .collection('users')
        .document(myId)
        .collection('friends')
        .document(document['id'])
        .setData({
          'id': document['id'],
        }
    );
    Firestore.instance
        .collection('users')
        .document(document['id'])
        .collection('friends')
        .document(myId)
        .setData({
          'id': myId,
    });

  }
}