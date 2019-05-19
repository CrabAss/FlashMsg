import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flashmsg/config/const.dart';
import 'package:flashmsg/db/friend/bloc.dart';
import 'package:flashmsg/state/account.dart';
import 'package:flashmsg/view/photo_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

class Chat extends StatelessWidget {

  Chat({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    PeerAccount peerAccount = Provider.of<PeerAccount>(context);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(
          peerAccount.nickname,
          style: TextStyle(color: whiteColor),
        ),
      ),
      body: new ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {

  ChatScreen({Key key}) : super(key: key);

  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  ChatScreenState({Key key});

  PeerAccount peerAccount;
  MyAccount myAccount;
  FriendBloc friendBloc;

  List<DocumentSnapshot> listMessage;
  String groupChatId;

  File imageFile;
  bool isLoading;

  String imageUrl;

/*
  @override
  void dispose() {
    friendBloc.dispose();
    super.dispose();
  }
*/

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    isLoading = false;
    imageUrl = '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    peerAccount = Provider.of<PeerAccount>(context);
    myAccount = Provider.of<MyAccount>(context);
    friendBloc = Provider.of<FriendBloc>(context);

    if (myAccount.id.hashCode <= peerAccount.id.hashCode) {
      groupChatId = '${myAccount.id}-${peerAccount.id}';
    } else {
      groupChatId = '${peerAccount.id}-${myAccount.id}';
    }
  }

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image
    if (content.trim() != '') {
      textEditingController.clear();
      String now = DateTime.now().millisecondsSinceEpoch.toString();

      var documentReference = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(now);

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'idFrom': myAccount.id,
            'idTo': peerAccount.id,
            'timestamp': now,
            'content': content,
            'type': type
          },
        );
      });
      friendBloc.updateFriend(peerAccount.id, now, type == 1 ? "[Image]" : content);
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    final double MAX_WIDTH = MediaQuery.of(context).size.width - 70.0;
    if (document['idFrom'] == myAccount.id) {
      // Right (my message)
      final radius = BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
          bottomLeft: Radius.circular(15.0),
          bottomRight: isLastMessageRight(index)
              ? Radius.circular(0.0)
              : Radius.circular(15.0));
      return Row(
        children: <Widget>[
          document['type'] == 0
              // Text
              ? Flexible(
                  child: GestureDetector(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MAX_WIDTH,
                    ),
                    child: Text(
                      document['content'],
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                    decoration:
                        BoxDecoration(color: whiteColor, borderRadius: radius),
                    margin: EdgeInsets.only(
                        bottom: isLastMessageRight(index) ? 20.0 : 2.0,
                        right: 10.0),
                  ),
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: document['content']))
                        .then((void res) {
                      Vibration.vibrate(duration: 50);
                      Fluttertoast.showToast(msg: "Copied to clipboard");
                    });
                  },
                ))
              : Container(
                  child: Material(
                    child: GestureDetector(
                      child: Hero(
                        tag: document['content'],
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(themeColor),
                                ),
                                width: 200.0,
                                height: 200.0,
                                padding: EdgeInsets.all(70.0),
                                decoration: BoxDecoration(
                                  color: greyColor2,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                ),
                              ),
                          errorWidget: (context, url, error) => Material(
                                child: Image.asset(
                                  'images/img_not_available.jpeg',
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                                clipBehavior: Clip.hardEdge,
                              ),
                          imageUrl: document['content'],
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                      onTap: () => Navigator.push(
                          context,
                          PageTransition(
                              child: PhotoViewScreen(photoUrl: document['content']),
                              type: PageTransitionType.fade
                          )
                      ),
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  margin: EdgeInsets.only(
                      bottom: isLastMessageRight(index) ? 10.0 : 2.0,
                      right: 10.0),
                )
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      final radius = BorderRadius.only(
        topLeft: Radius.circular(15.0),
        topRight: Radius.circular(15.0),
        bottomLeft: isLastMessageLeft(index)
            ? Radius.circular(0.0)
            : Radius.circular(15.0),
        bottomRight: Radius.circular(15.0),
      );
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                isLastMessageLeft(index)
                    ? Material(
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.0,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(themeColor),
                                ),
                                width: 35.0,
                                height: 35.0,
                                padding: EdgeInsets.all(10.0),
                              ),
                          imageUrl: peerAccount.photoUrl,
                          width: 35.0,
                          height: 35.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(18.0),
                        ),
                        clipBehavior: Clip.hardEdge,
                      )
                    : Container(width: 35.0),
                document['type'] == 0
                    ? Flexible(
                        child: GestureDetector(
                        child: Container(
                          constraints:
                              BoxConstraints(maxWidth: MAX_WIDTH - 40.0),
                          child: Text(
                            document['content'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                          decoration: BoxDecoration(
                              color: themeColor, borderRadius: radius),
                          margin: EdgeInsets.only(left: 5.0),
                        ),
                        onLongPress: () {
                          Clipboard.setData(
                                  ClipboardData(text: document['content']))
                              .then((void res) {
                            Vibration.vibrate(duration: 50);
                            Fluttertoast.showToast(msg: "Copied to clipboard");
                          });
                        },
                      ))
                    : Container(
                        child: Material(
                          child: GestureDetector(
                            child: Hero(
                              tag: document['content'],
                              child: CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                themeColor),
                                      ),
                                      width: 200.0,
                                      height: 200.0,
                                      padding: EdgeInsets.all(70.0),
                                      decoration: BoxDecoration(
                                        color: greyColor2,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                errorWidget: (context, url, error) => Material(
                                      child: Image.asset(
                                        'images/img_not_available.jpeg',
                                        width: 200.0,
                                        height: 200.0,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                                imageUrl: document['content'],
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                            onTap: () => Navigator.push(
                                context,
                                PageTransition(
                                    child: PhotoViewScreen(photoUrl: document['content']),
                                    type: PageTransitionType.fade
                                )
                            ),                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                        margin: EdgeInsets.only(left: 10.0),
                      ),
              ],
            ),

            // Time
            isLastMessageLeft(index)
                ? Container(
                    child: Text(
                      DateFormat('dd MMM kk:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              int.parse(document['timestamp']))),
                      style: TextStyle(
                          color: greyColor,
                          fontSize: 12.0,
                          fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(left: 55.0, top: 5.0, bottom: 5.0),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: isLastMessageLeft(index) ? 10.0 : 2.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] == myAccount.id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] != myAccount.id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            buildListMessage(),
            buildInput(),
          ],
        ),
        buildLoading()
      ],
    );
  }

  Widget buildLoading() {
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

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.image),
                onPressed: getImage,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: primaryColor, fontSize: 16.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: greyColor),
                ),
                focusNode: focusNode,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                autofocus: true,
              ),
            ),
          ),

          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => onSendMessage(textEditingController.text, 0),
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border:
              new Border(top: new BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('messages')
                  .document(groupChatId)
                  .collection(groupChatId)
                  .orderBy('timestamp', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  listMessage = snapshot.data.documents;
                  return Container(
                    color: greyColor2,
                    child: ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) =>
                          buildItem(index, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                      reverse: true,
                      controller: listScrollController,
                    ),
                  );
                }
              },
            ),
    );
  }
}
