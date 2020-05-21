import 'dart:collection';
import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc_demo/Modal/Messages.dart';
import 'package:flutter_webrtc_demo/Modal/SmallMessage.dart';
import 'package:flutter_webrtc_demo/src/call_sample/signaling_config.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:core';
import 'signaling.dart';
import 'package:flutter_webrtc/webrtc.dart';

class VideoSample extends StatefulWidget {
  static String tag = 'Video_sample';
  final String ip;
  final String messageId;
  VideoSample({Key key, @required this.ip, this.messageId}) : super(key: key);

  @override
  _VideoSampleState createState() =>
      new _VideoSampleState(serverIP: ip, messageId: messageId);
}

enum DialogDemoAction {
  cancel,
  connect,
}

class _VideoSampleState extends State<VideoSample> {
  SignalingConf _signaling;
  List<dynamic> _peers;
  dynamic _selfId;
  bool showFab = true;
  RTCDataChannel _dataChannel;
  var _text = '';
  String _peerAddress = "9999999";
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _secondremoteRenderer = new RTCVideoRenderer();
  bool _inCalling = false;
  String _imageUrl;
  final String serverIP;
  final String messageId;
  List<Messages> allmessages;
  TextEditingController _textcontroller = new TextEditingController();
  final dbRef = FirebaseDatabase.instance.reference();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController _scrollController = ScrollController();
  bool audio = false;
  bool video = false;
  _VideoSampleState({Key key, @required this.serverIP, this.messageId});

  @override
  initState() {
    super.initState();
    _peers = [];
    allmessages = [];
    _peerAddress = "9999999";
    print(messageId);
    initRenderers();
    _connect();
    getSelfId().then((value) {
      _selfId = value;
      getDetail(_selfId);
    });
  }

  Future<String> getSelfId() async {
    SharedPreferences _pref = await SharedPreferences.getInstance();
    String id = _pref.getString('MessageId');
    return id;
  }

  getDetail(String _selfId) async {
    LinkedHashMap<dynamic, dynamic> _detail = LinkedHashMap<dynamic, dynamic>();

    await dbRef
        .child('Users')
        .orderByChild('MessagesId')
        .equalTo(_selfId)
        .once()
        .then((DataSnapshot snapshot) {
      _detail = snapshot.value;
      _detail.values.forEach((element) {
        _imageUrl = element['PhotoUrl'];
      });
    });
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _secondremoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    if (_signaling != null) _signaling.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _secondremoteRenderer.dispose();
  }

  void _connect() async {
    if (_signaling == null) {
      print(serverIP);
      print(messageId);
      _signaling = new SignalingConf(serverIP)..connect();

      _signaling.onDataChannelMessage = (dc, RTCDataChannelMessage data) {
        
        Provider.of<SmallMessages>(context)
            .addSmallMessages(data.text, _peerAddress);
      };

      _signaling.onDataChannel = (channel) {
        _dataChannel = channel;
      };

      _signaling.onStateChange = (SignalingConfState state) {
        switch (state) {
          case SignalingConfState.CallStateNew:
            this.setState(() {
              _inCalling = true;
            });
            break;
          case SignalingConfState.CallStateBye:
            this.setState(() {
              _localRenderer.srcObject = null;
              _remoteRenderer.srcObject = null;
              _secondremoteRenderer.srcObject = null;
              _inCalling = false;
              _dataChannel = null;
              _text = '';
            });
            break;
          case SignalingConfState.CallStateInvite:
          case SignalingConfState.CallStateConnected:
          case SignalingConfState.CallStateRinging:
          case SignalingConfState.ConnectionClosed:
          case SignalingConfState.ConnectionError:
          case SignalingConfState.ConnectionOpen:
            // this.setState(() {
            //     _inCalling = true;
            //   });
            //   break;

            break;
        }
      };

      _signaling.onPeersUpdate = ((event) {
        this.setState(() {
          _selfId = event['self'];
          _peers.add(event['peers']);
          print(_selfId);
          print(_peers[0]);
        });
      });

      _signaling.onLocalStream = ((stream) {
        _localRenderer.srcObject = stream;
      });

      _signaling.onAddRemoteStream = ((stream) {
        _remoteRenderer.srcObject = (stream.getVideoTracks()[0]) as MediaStream;
        _secondremoteRenderer.srcObject = (stream.getVideoTracks()[1]) as MediaStream;
        print(stream.id);
        // if(stream.id=='stream1'){
        //   _remoteRenderer.srcObject = stream;
        // }
        // else if(stream.id=='stream2'){
        // _secondremoteRenderer.srcObject = stream;
        // }
      });

      _signaling.onRemoveRemoteStream = ((stream) {
        _remoteRenderer.srcObject = null;
        _secondremoteRenderer.srcObject = null;
      });
    }
  }

  _invitePeer(context, peerId, use_screen) async {
    if (_signaling != null && peerId != _selfId) {
      _signaling.invite(peerId, 'video', use_screen);
    }
  }

  _hangUp() {
    if (_signaling != null) {
      _signaling.bye();
    }
  }

  _switchCamera() {
    _signaling.switchCamera();
  }

  _muteAudio() {
    audio = !audio;
    _signaling.muteaudio(audio);
  }

  _muteVideo() {
    video = !video;
    _signaling.mutevideo(video);
  }

  _showModalBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: 250.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ListTile(
                  leading: audio ? Icon(Icons.mic_off) : Icon(Icons.mic_none),
                  onTap: () {
                    _muteAudio();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading:
                      video ? Icon(Icons.videocam_off) : Icon(Icons.videocam),
                  onTap: () {
                    _muteVideo();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  _handleDataChannelTest() async {
    if (_dataChannel != null) {
      String text = _textcontroller.text;
      // setState(() {
      //   allmessages.add(Messages(text, _selfId));
      // });
      if (text != null)
        await Provider.of<SmallMessages>(context)
            .addSmallMessages(text, _selfId);

      _dataChannel.send(RTCDataChannelMessage.fromBinary(Uint8List(1)));
      _dataChannel.send(RTCDataChannelMessage(text));
    }
  }

  _buildMessage(BuildContext context, Messages message, bool isMe) {
    final Container msg = Container(
      margin: isMe
          ? EdgeInsets.only(top: 8.0, bottom: 8.0, left: 80.0)
          : EdgeInsets.only(top: 8.0, bottom: 8.0),
      padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: isMe ? Color.fromRGBO(227, 174, 230, 1) : Color(0xFFFFEFEE),
        borderRadius: isMe
            ? BorderRadius.only( 
                topLeft: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0))
            : BorderRadius.only(
                topRight: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            DateFormat('jms').format(new DateTime.now()),
            style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 16.0,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 5.0),
          Text(message.text,
              style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
    if (isMe) {
      return msg;
    }
    return Row(
      children: <Widget>[
        msg,
        IconButton(
            icon: Icon(Icons.favorite_border),
            color: Colors.black,
            iconSize: 30.0,
            onPressed: () {})
      ],
    );
  }

  _buildMessageComposer(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        height: 70.0,
        color: Colors.white,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.photo),
              iconSize: 25.0,
              color: Theme.of(context).primaryColor,
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _textcontroller,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {},
                decoration: InputDecoration.collapsed(
                  hintText: 'Send a message...',
                ),
              ),
            ),
            IconButton( 
              icon: Icon(Icons.send),
              iconSize: 25.0,
              color: Theme.of(context).primaryColor,
              onPressed: () {
                _handleDataChannelTest();
                _textcontroller.clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    showDialog(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        if (value == DialogDemoAction.connect) {
          _signaling.checkPeer(_peerAddress);
        }
      }
    });
  }

  _showAddressDialog(context) {
    showDemoDialog<DialogDemoAction>(
        context: context,
        child: new AlertDialog(
            title: const Text('Enter Peer Address:'),
            content: TextField(
              onChanged: (String text) {
                _peerAddress = text;
              },
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.cancel);
                  }),
              new FlatButton(
                  child: const Text('CONNECT'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.connect);
                  })
            ]));
  }

  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  _buildRow(context, peer) {
    print(peer);
    print(_selfId);
    var self = (peer['id'] == _selfId);
    return ListBody(children: <Widget>[
      ListTile(
        leading: Container(
          height: 50.0,
          width: 50.0,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0)),
          child: Image.network(
                  'https://cdn3.vectorstock.com/i/1000x1000/48/02/icon-man-silhouette-vector-13904802.jpg'),
        ),
        title: Text(self
            ? "Welcome " + peer['name'] ?? "host"
            : peer['name']),
        trailing: self
            ? IconButton(
                icon: const Icon(Icons.add_to_queue),
                onPressed: () {
                  _showAddressDialog(context);
                },
                tooltip: 'Video calling',
              )
            : new SizedBox(
                width: 100.0,
                child: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.videocam),
                        onPressed: () =>
                            _invitePeer(context, peer['id'], false),
                        tooltip: 'Video calling',
                      ),
                      IconButton(
                        icon: const Icon(Icons.screen_share),
                        onPressed: () => _invitePeer(context, peer['id'], true),
                        tooltip: 'Screen sharing',
                      )
                    ])),
        subtitle: Text('id: ' + peer['id']),
      ),
      Divider()
    ]);
  }

  void showFoatingActionButton(bool value) {
    setState(() {
      showFab = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Text('Video Call'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: null,
            tooltip: 'setup',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _inCalling && showFab
          ? new SizedBox(
              width: 200.0,
              child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    FloatingActionButton(
                      child: const Icon(Icons.switch_camera),
                      onPressed: _switchCamera,
                      mini: true,
                    ),
                    FloatingActionButton(
                      onPressed: _hangUp,
                      tooltip: 'Hangup',
                      mini: true,
                      child: new Icon(Icons.call_end),
                      backgroundColor: Colors.pink,
                    ),
                    FloatingActionButton(
                      child: const Icon(Icons.stop),
                      tooltip: 'mic_off',
                      mini: true,
                      onPressed: _showModalBottomSheet,
                    ),
                    FloatingActionButton(
                        child: const Icon(Icons.chat),
                        mini: true,
                        onPressed: () {
                          var bottomSheetController =
                              scaffoldKey.currentState.showBottomSheet(
                            (context) => GestureDetector(
                              onTap: () => {FocusScope.of(context).unfocus()},
                              child: Column(
                                children: <Widget>[
                                  Expanded(
                                    flex: 5,
                                    child: Container(
                                        height: 250.0,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(30.0),
                                                topRight:
                                                    Radius.circular(30.0))),
                                        child: Consumer<SmallMessages>(builder:
                                            (context, peermessage, child) {
                                          return ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      Radius.circular(30.0),
                                                  topRight:
                                                      Radius.circular(30.0)),
                                              child: ListView.builder(
                                                  controller: _scrollController,
                                                  reverse: false,
                                                  padding: EdgeInsets.only(
                                                      top: 15.0),
                                                  itemCount: peermessage
                                                      .allSmallMessages.length,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    final message = peermessage
                                                            .allSmallMessages[
                                                        index];
                                                    final bool isMe =
                                                        message.id == _selfId;
                                                    return _buildMessage(
                                                        context, message, isMe);
                                                  }));
                                        })),
                                  ),
                                  _buildMessageComposer(context)
                                ],
                              ),
                            ),
                          );
                          showFoatingActionButton(false);
                          bottomSheetController.closed.then((value) {
                            showFoatingActionButton(true);
                          });
                        })
                  ]))
          : null,
      body: _inCalling
          ? OrientationBuilder(builder: (context, orientation) {
              return new Container(
                child: new Stack(children: <Widget>[
                  new Positioned(
                      left: 30.0,
                      //right: 0.0,
                      top: 0.0,
                      bottom: 0.0,
                      child: new Container(
                        margin: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        width: MediaQuery.of(context).size.width*0.3,
                        height: MediaQuery.of(context).size.height,
                        child: new RTCVideoView(_remoteRenderer),
                        decoration: new BoxDecoration(color: Colors.black54),
                      )),
                  new Positioned(
                      //left: 0.0,
                      right: 30.0,
                      top: 0.0,
                      bottom: 0.0,
                      child: new Container(
                        margin: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        width: MediaQuery.of(context).size.width*0.3,
                        height: MediaQuery.of(context).size.height,
                        child: new RTCVideoView(_secondremoteRenderer),
                        decoration: new BoxDecoration(color: Colors.black54),
                      )),    
                  new Positioned(
                    left: 20.0,
                    top: 20.0,
                    child: new Container(
                      width: orientation == Orientation.portrait ? 90.0 : 120.0,
                      height:
                          orientation == Orientation.portrait ? 120.0 : 90.0,
                      child: new RTCVideoView(_localRenderer),
                      decoration: new BoxDecoration(color: Colors.black54),
                    ),
                  ),
                ]),
              );
            })
          : new ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(0.0),
              itemCount: (_peers != null ? _peers.length : 0),
              itemBuilder: (context, i) {
                return _buildRow(context, _peers[i]);
              }),
    );
  }
}
