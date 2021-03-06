import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helping_hand/config/config.dart';
import 'package:helping_hand/models/message_model.dart';
import 'package:helping_hand/models/user_model_for_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ChatScreen extends StatefulWidget {
  final User theOtherPerson;
  final String messageField;

  ChatScreen({this.theOtherPerson, this.messageField});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController textEditingController = TextEditingController();

  String text;
  String me;
  ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    get_me();
    showThaksButton();
    message_read();
    super.initState();
  }

  @override
  void dispose() {
    is_not_typing();
    super.dispose();
  }

  Future<void> get_me() async {
    final auth = FirebaseAuth.instance;
    final FirebaseUser sender = await auth.currentUser();
    final senderID = sender.uid;

    setState(() {
      me = senderID;
    });
  }

  Future<void> is_typing() async {
    final DocumentReference senderData = Firestore.instance
        .document(widget.messageField + '/perticipents/' + me);

    await senderData.setData({'typing': true}, merge: true);
  }

  Future<void> is_not_typing() async {
    final DocumentReference senderData = Firestore.instance
        .document(widget.messageField + '/perticipents/' + me);

    await senderData.setData({'typing': false}, merge: true);
  }

  _buildMessage(Message message, bool isMe) {
    final Container msg = Container(
      margin: isMe
          ? EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
              left: 80.0,
            )
          : EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
            ),
      padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: isMe ? primaryColor : secondaryColor,
        borderRadius: isMe
            ? BorderRadius.only(
                topLeft: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0),
              )
            : BorderRadius.only(
                topRight: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${message.time.toDate().hour}:${message.time.toDate().minute}:${message.time.toDate().second}',
            style: bodyTextStyle.copyWith(fontSize: 8),
          ),
          SizedBox(height: 8.0),
          Text(message.text,
              style: bodyTextStyle.copyWith(color: Colors.white)),
        ],
      ),
    );
    if (isMe) {
      return msg;
    }
    return Row(
      children: <Widget>[
        msg,
        // IconButton(
        //   icon: message.isLiked
        //       ? Icon(Icons.favorite)
        //       : Icon(Icons.favorite_border),
        //   iconSize: 30.0,
        //   color: message.isLiked
        //       ? Theme.of(context).primaryColor
        //       : Colors.blueGrey,
        //   onPressed: () async{
        //     final CollectionReference messageFieldCollection =  Firestore.instance.collection(widget.messageField+'/texts');

        //     await messageFieldCollection.document(message.textID).setData({
        //       'isLiked': true
        //     }, merge: true);
        //   },
        // )
      ],
    );
  }

  _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      color: Colors.white,
      child: Column(
        children: <Widget>[
          StreamBuilder(
            stream: Firestore.instance
                .collection(widget.messageField + '/perticipents')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                if (snapshot.data.documents[0]['id'] ==
                    widget.theOtherPerson.id) {
                  if (snapshot.data.documents[0]['typing'] == true) {
                    return TypewriterAnimatedTextKit(
                        onTap: () {},
                        text: [
                          "Typing.....",
                        ],
                        textStyle: bodyTextStyle.copyWith(color: Colors.black),
                        textAlign: TextAlign.start,
                        alignment: AlignmentDirectional
                            .topStart // or Alignment.topLeft
                        );
                  }
                } else if (snapshot.data.documents[1]['id'] ==
                    widget.theOtherPerson.id) {
                  if (snapshot.data.documents[1]['typing'] == true) {
                    return TypewriterAnimatedTextKit(
                        onTap: () {},
                        text: [
                          "Typing.....",
                        ],
                        textStyle: bodyTextStyle.copyWith(color: Colors.black),
                        textAlign: TextAlign.start,
                        alignment: AlignmentDirectional
                            .topStart // or Alignment.topLeft
                        );
                  }
                }
              }
              return Container(
                height: 0.0,
                width: 0.0,
              );
            },
          ),
          Row(
            children: <Widget>[
              // IconButton(
              //   icon: Icon(Icons.subdirectory_arrow_right),
              //   iconSize: 25.0,
              //   color: Theme.of(context).primaryColor,
              //   onPressed: () {},
              // ),
              Expanded(
                child: TextField(
                  controller: textEditingController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    text = value;
                    if (value != null && value != "") {
                      is_typing();
                    } else {
                      is_not_typing();
                    }
                  },
                  decoration: InputDecoration.collapsed(
                    hintText: 'Send a message...',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                iconSize: 25.0,
                color: Theme.of(context).primaryColor,
                onPressed: () async {
                  if (text != "" && text != null) {
                    sendMessages();
                  }
                  is_not_typing();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void sendMessages() async {
    textEditingController.clear();
    final auth = FirebaseAuth.instance;
    final FirebaseUser sender = await auth.currentUser();
    final senderID = sender.uid;

    final CollectionReference messageFieldCollection =
        Firestore.instance.collection(widget.messageField + '/texts');

    final DocumentReference senderData = Firestore.instance
        .document(widget.messageField + '/perticipents/' + senderID);

    Map<String, dynamic> sender_info;

    await for (var snapshot in senderData.snapshots()) {
      setState(() {
        sender_info = snapshot.data;
      });
      break;
    }

    await messageFieldCollection.document().setData({
      'sender_id': senderID,
      'sender_photUrl': sender_info['photUrl'],
      'sender_name': sender_info['name'],
      'time': DateTime.now(),
      'text': text,
      'isLiked': false,
      'unread': true,
    }, merge: true);

    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  bool showthnksButton = false;

  Future<void> showThaksButton() async {
    final DocumentReference messages = Firestore.instance.document(
        widget.messageField + '/perticipents/' + widget.theOtherPerson.id);

    await for (var snapshot in messages.snapshots()) {
      if (snapshot.data['position'] == 'helper') {
        if (snapshot.data['thanked'] == false ||
            snapshot.data['thanked'] == null) {
          setState(() {
            showthnksButton = true;
          });
          //
        } else if (snapshot.data['thanked'] == true) {
          setState(() {
            showthnksButton = false;
          });
          //
        }
      }
    }
  }

  Future<void> thankYou() async {
    final DocumentReference messages = Firestore.instance.document(
        widget.messageField + '/perticipents/' + widget.theOtherPerson.id);

    await messages.setData({'thanked': true}, merge: true);

    final DocumentReference otherPerson =
        Firestore.instance.document('users/' + widget.theOtherPerson.id);

    int points = 0, peopleHelped = 0;

    await for (var snapshot in otherPerson.snapshots()) {
      if (snapshot.data['points'] != null) {
        points = snapshot.data['points'] + 5;
      } else {
        points = 5;
      }
      if (snapshot.data['peopleHelped'] != null) {
        peopleHelped = snapshot.data['peopleHelped'] + 1;
      } else {
        peopleHelped = 1;
      }
      break;
    }

    await otherPerson
        .setData({'points': points, 'peopleHelped': peopleHelped}, merge: true);
  }

  Future<void> message_read() async {
    final CollectionReference texts =
        Firestore.instance.collection(widget.messageField + '/texts');

    await for (var snapshot in texts.snapshots()) {
      for (var text in snapshot.documents) {
        final DocumentReference textDocument = Firestore.instance
            .document(widget.messageField + '/texts/' + text.documentID);
        if (text.data['sender_ID'] == widget.theOtherPerson.id) {
          textDocument.setData({'unread': false}, merge: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //this little code down here turns off auto rotation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 16.0),
            child: Container(
              //margin: EdgeInsets.only(top: 4),
              alignment: Alignment.center,
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: showthnksButton ? secondaryColor : primaryColor,
              ),
              child: InkWell(
                onTap: () {
                  if (showthnksButton == true) {
                    thankYou();
                    showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            title: Text(
                              "You have thanked the person",
                              style:
                                  titleTextStyle.copyWith(color: Colors.green),
                            ),
                            content: Text(
                              "We will let the person know that you appreciated the help and add perks to that person's profile",
                              style: bodyTextStyle,
                            ),
                            actions: <Widget>[
                              FlatButton(
                                child: Text(
                                  "Okay",
                                  style: titleTextStyle.copyWith(
                                      color: Colors.green, fontSize: 16),
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                },
                              ),
                            ],
                          );
                        });
                  }
                  showThaksButton();
                },
                child: showthnksButton
                    ? Container(
                        child: Text(
                          "🌟 Say Thanks",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      )
                    : Container(
                        child: Text(
                          "",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
              ),
            ),
          ),
        ],
        title: Text(
          widget.theOtherPerson.name,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0.0,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                child: StreamBuilder(
                  stream: Firestore.instance
                      .collection(widget.messageField + '/texts')
                      .orderBy('time', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        shrinkWrap: true,
                        padding: EdgeInsets.only(top: 15.0),
                        itemCount: snapshot.data.documents.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Message message = new Message(
                              sender: User(
                                id: snapshot.data.documents[index]['sender_id'],
                                imageUrl: snapshot.data.documents[index]
                                    ['sender_photUrl'],
                                name: snapshot.data.documents[index]
                                    ['sender_name'],
                              ),
                              time: snapshot.data.documents[index]['time'],
                              text: snapshot.data.documents[index]['text'],
                              isLiked: snapshot.data.documents[index]
                                  ['isLiked'],
                              unread: snapshot.data.documents[index]['unread'],
                              textID:
                                  snapshot.data.documents[index].documentID);

                          final bool isMe =
                              snapshot.data.documents[index]['sender_id'] == me;
                          return _buildMessage(message, isMe);
                        },
                      );
                    }
                    return Container(
                      height: 0.0,
                      width: 0.0,
                    );
                  },
                ),
              ),
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }
}
