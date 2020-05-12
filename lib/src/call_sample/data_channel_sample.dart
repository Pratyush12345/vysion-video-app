import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:core';
import 'dart:async';
import 'dart:typed_data';
import 'signaling.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:flutter_webrtc_demo/Modal/Messages.dart';
class DataChannelSample extends StatefulWidget {
  static String tag = 'call_sample';

  final String ip;
  final String messageId;

  DataChannelSample({Key key, @required this.ip, this.messageId}) : super(key: key);

  @override
  _DataChannelSampleState createState() =>
      new _DataChannelSampleState(serverIP: ip, messageId: messageId);
}

enum DialogDemoAction {
  cancel,
  connect,
}

class _DataChannelSampleState extends State<DataChannelSample> {
  Signaling _signaling;
  List<dynamic> _peers;
  dynamic _selfId;
  String _peerAddress = "999999";
  bool _inCalling = false;
  final String serverIP;
  RTCDataChannel _dataChannel;
  Timer _timer;
  var _text = '';
  final String messageId;
  String _inputMessage = "";
  List<Messages> allmessages;
  TextEditingController _textcontroller=new TextEditingController();
  ScrollController _scrollController = ScrollController();
  _DataChannelSampleState({Key key, @required this.serverIP, this.messageId});

  @override
  initState() {
    super.initState();
    _peers = [];
    allmessages=[];
    _peerAddress = "";
    _connect();
  }

  @override
  deactivate() {
    super.deactivate();
    if (_signaling != null) _signaling.close();
    if (_timer != null) {
      _timer.cancel();
    }
  }
  _scrollToBottom() {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }

  void _connect() async {
    if (_signaling == null) {
      _signaling = new Signaling(serverIP)..connect();

      _signaling.onDataChannelMessage = (dc, RTCDataChannelMessage data) {
        setState(() {
          if (data.isBinary) {
            print('Got binary [' + data.binary.toString() + ']');
          } else {
            _text = data.text;
            allmessages.add(Messages(_text,_peerAddress));
          }
        });
      };

      _signaling.onDataChannel = (channel) {
        _dataChannel = channel;
      };

      _signaling.onStateChange = (SignalingState state) {
        switch (state) {
          case SignalingState.CallStateNew:
            {
              this.setState(() {
                _inCalling = true;
              });
              // _timer = new Timer.periodic(
              //     Duration(seconds: 1), _handleDataChannelTest);
              break;
            }
          case SignalingState.CallStateBye:
            {
              this.setState(() {
                _inCalling = false;
              });
              if (_timer != null) {
                _timer.cancel();
                _timer = null;
              }
              _dataChannel = null;
              _text = '';
              break;
            }
          case SignalingState.CallStateInvite:
          case SignalingState.CallStateConnected:
          case SignalingState.CallStateRinging:
          case SignalingState.ConnectionClosed:
          case SignalingState.ConnectionError:
          case SignalingState.ConnectionOpen:
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
    }
  }

  _handleDataChannelTest() async {
    if (_dataChannel != null) {
      String text = _textcontroller.text;
      setState(() {
        allmessages.add(Messages(text, _selfId));
      });
      _dataChannel
          .send(RTCDataChannelMessage.fromBinary(Uint8List(1)));
      _dataChannel.send(RTCDataChannelMessage(text));
    }
  }

  _invitePeer(context, peerId) async {
    if (_signaling != null && peerId != _selfId) {
      _signaling.invite(peerId, 'data', false);
    }
  }

  _hangUp() {
    if (_signaling != null) {
      _signaling.bye();
    }
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
            title: const Text('Enter peer address:'),
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

  _buildRow(context, peer) {
    print(peer);
    print(_selfId);
    var self = (peer['id'] == _selfId);
    return ListBody(children: <Widget>[
      ListTile(
        leading: Container(
                  height: 50.0,
                          width: 50.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0)
                  ),
                  child: Image.network( peer['imageUrl'],
                          
                          ),
        ),
        title: Text(self
            ? "Welcome " + peer['currentUser']
            : peer['currentUser']),
        onTap: () {
          _showAddressDialog(context);
        },
        trailing: SizedBox(
            width: 100.0,
            child: IconButton(
                onPressed: () => {_invitePeer(context, peer['id'])},
                icon: Icon(Icons.sms))),
        subtitle: Text('id: ' + peer['id']),
      ),
      Divider()
    ]);
  }

  _buildMessage(Messages message, bool isMe){

    final Container msg= Container(
          margin: isMe?EdgeInsets.only(top: 8.0, bottom: 8.0, left: 80.0): EdgeInsets.only(top:8.0, bottom: 8.0),
          padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
          width: MediaQuery.of(context).size.width*0.75,
          decoration: BoxDecoration(
            color: isMe?Color.fromRGBO(227, 174, 230, 1): Color(0xFFFFEFEE),
            borderRadius: isMe? BorderRadius.only(
                        topLeft: Radius.circular(30.0),
                        bottomLeft: Radius.circular(30.0)
                      ):
                      BorderRadius.only(
                        topRight: Radius.circular(30.0),
                        bottomRight: Radius.circular(30.0)
                      ),
          
          ),
                    
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text( DateFormat('jms').format(new DateTime.now()),
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600
                ),),
                
                SizedBox(height: 5.0),
                Text(message.text,
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600
                )),
              ],
            ),

        );
  if(isMe){
    return msg;
  }
    return Row(
      children: <Widget>[
        msg,
        IconButton(
            icon: Icon(Icons.favorite_border), 
            color: Colors.black,
            iconSize: 30.0,
            onPressed: (){})
            
      ],
    );
  }

  _buildMessageComposer() {
    return Container(
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

            },
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Chit - Chat'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: null,
            tooltip: 'setup',
          ),
        ],
      ),
      // floatingActionButton: _inCalling
      //     ? FloatingActionButton(
      //         onPressed: _hangUp,
      //         tooltip: 'Hangup',
      //         child: new Icon(Icons.call_end),
      //       )
      //     : null,
      body: _inCalling
          ? GestureDetector(
          onTap: ()=>{
            FocusScope.of(context).unfocus()
          },
                  child: Column(
            children: <Widget>[
              Expanded(
                            child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0)
                    )
                  ),
                  child: ClipRRect(
                       borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0)
                          ),
                                            child: ListView.builder(
                            reverse: false,
                            controller: _scrollController,                  
                           padding: EdgeInsets.only(top: 15.0),                   
                          itemCount: allmessages.length,
                          itemBuilder: (BuildContext context, int index){
                            final message=allmessages[index];
                            final bool isMe=message.id==_selfId;
                            return _buildMessage(message, isMe);
                          }),
                      )
                     ),
              ),
            _buildMessageComposer()
            ],
          ),
        )
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
