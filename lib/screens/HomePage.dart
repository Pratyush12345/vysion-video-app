import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc_demo/Authentication/User.dart';
import 'package:flutter_webrtc_demo/src/basic_sample/basic_sample.dart';
import 'package:flutter_webrtc_demo/src/call_sample/call_sample.dart';
import 'package:flutter_webrtc_demo/src/call_sample/data_channel_sample.dart';
import 'package:flutter_webrtc_demo/src/call_sample/video_call.dart';
import 'package:flutter_webrtc_demo/src/route_item.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_webrtc_demo/Modal/SmallMessage.dart';
import 'dart:convert';
class HomePage extends StatefulWidget {
  //String selfId;
  HomePage();
  @override
  _HomePageState createState() => _HomePageState();
}

enum DialogDemoAction {
  cancel,
  connect,
}
class _HomePageState extends State<HomePage> {
  // String selfId;
  _HomePageState();
  List<RouteItem> items;
  String _server = '';
  SharedPreferences _prefs;
  final dbRef=FirebaseDatabase.instance.reference();
  bool _datachannel = false;
  
  List<dynamic> _list=[];
  @override
  initState() {
    super.initState();
    _initData();
    _initItems();
    // getSelfId().then((value) {
    //   selfId=value;
    //   print('//////////////$value?????');
    //   print('//////////////$selfId?????');
    //   getDetail(selfId).then((value) {
    //   print('//////$value');
    //   });

    //   });
      
  }
  // Future<LinkedHashMap<dynamic, dynamic>> getDetail(String _selfId) async{
   
  //   LinkedHashMap<dynamic, dynamic> _detail=LinkedHashMap<dynamic,dynamic>();
  //   await dbRef.child('Users').orderByChild('MessagesId').equalTo(_selfId).once().then((DataSnapshot snapshot) {
  //   print('//////////////$snapshot?????');  
  //   print('///${snapshot.key}');
  //   print('///${snapshot.value}');
  //   _detail=snapshot.value;
  //   });
  //  return _detail;  
  // }
  // Future<String> getSelfId() async{
  //       SharedPreferences _pref = await SharedPreferences.getInstance();
  //       String id=_pref.getString('MessageId');
  //       return id;
  //   }


  _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    
     return new Scaffold(
          appBar: new AppBar(
            title: new Text('Friends Family'),
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
                      child: new ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(0.0),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  return _buildRow(context, items[i]);
                }),
          ));
  }

  _initData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _server = _prefs.getString('server') ?? 'demo.cloudwebrtc.com';
      print( _prefs.getString('MessageId'));
    });
  }

  _initItems() {
    items = <RouteItem>[
      RouteItem(
          title: 'Media Test',
          subtitle: 'Basic API Tests.',
          push: (BuildContext context) {
            Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (BuildContext context) => new BasicSample()));
          }),
      RouteItem(
          title: 'Video Call',
          subtitle: 'P2P Call Sample.',
          push: (BuildContext context) {
            _datachannel = false;
           // _showAddressDialog(context);
           Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => _datachannel
                      ? DataChannelSample(ip: _server,)
                      : ChangeNotifierProvider<SmallMessages>(
                        create: (context)=> SmallMessages(),
                        child: CallSample(ip: "https://socket-video-server.herokuapp.com")
                        )));
          }),
      RouteItem(
          title: 'Chit - Chat',
          subtitle: 'P2P Data Channel.',
          push: (BuildContext context) {
            _datachannel = true;
            //_showAddressDialog(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => _datachannel
                      ? DataChannelSample(ip: "ws://localhost:1234")
                      : CallSample(ip: "https://socket-video-server.herokuapp.com")));
          }),

      RouteItem(
          title: 'Video Conferencing',
          subtitle: 'P2P Call Sample.',
          push: (BuildContext context) {
            
           Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => 
                       ChangeNotifierProvider<SmallMessages>(
                        create: (context)=> SmallMessages(),
                        child: VideoSample(ip: "ws://localhost:1234")
                        )));
          })    
    ];
  }
}