import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc_demo/Authentication/Constants.dart';
import 'package:flutter_webrtc_demo/Authentication/FirebaseAuth.dart';
import 'package:flutter_webrtc_demo/screens/HomePage.dart';
import 'package:flutter_webrtc_demo/src/call_sample/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeaturesPage extends StatefulWidget {
  String email, name, uid, photoUrl;
  FeaturesPage(this.email, this.name, this.uid, this.photoUrl);
  @override
  _FeaturesPageState createState() =>
      _FeaturesPageState(email, name, uid, photoUrl);
}

class _FeaturesPageState extends State<FeaturesPage> {
  String email, name, uid, photoUrl;
  String _selfId;
  final dbRef = FirebaseDatabase.instance.reference();
  SharedPreferences _pref;
  _FeaturesPageState(this.email, this.name, this.uid, this.photoUrl);

  _initData() async {
    _pref = await SharedPreferences.getInstance();

    if (_pref.getString('MessageId') == null)
      _pref.setString('MessageId', randomNumeric(6));

    print(_pref.getString('MessageId'));
    print(_pref.getString('signUpUserName'));

    dbRef.child("Users").child(uid).set({
      "Name": name ?? _pref.getString('signUpUserName'),
      "Email": email,
      "MessagesId": _pref.getString('MessageId') ?? randomNumeric(6),
      "PhotoUrl": photoUrl,
    });
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future showErrorDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(title: Text("Are You Sure ?"), actions: <Widget>[
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop("Yes");
              },
              elevation: 5.0,
              child: Text("Yes"),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.of(context).pop("No");
              },
              elevation: 5.0,
              child: Text("No"),
            )
          ]);
        });
  }

  void choiceAction(String choice) {
    if (choice == Constants.signout) {
      showErrorDialog(context).then((onValue) {
        if (onValue == "Yes") {
          FireBaseAuth().logout();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('VISION'), actions: <Widget>[
        PopupMenuButton<String>(
          onSelected: choiceAction,
          itemBuilder: (BuildContext context) {
            return Constants.choices.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        )
      ]),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => HomePage(_selfId)));
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 140.0,
                decoration: BoxDecoration(
                    color: Color.fromRGBO(227, 174, 230, 1),
                    borderRadius: BorderRadius.circular(10.0)),
                child: Center(
                  child: ListTile(
                    leading: Icon(Icons.people, color: Colors.purple),
                    title: Text('Friends and Family',
                        style: TextStyle(
                            fontSize: 23.0, fontWeight: FontWeight.w400)),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(10.0),
            child: GestureDetector(
              onTap: () {
                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (BuildContext context) => HomePage(_selfId)));
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 140.0,
                decoration: BoxDecoration(
                    color: Color.fromRGBO(227, 174, 230, 1),
                    borderRadius: BorderRadius.circular(10.0)),
                child: Center(
                  child: ListTile(
                    leading: Icon(Icons.book, color: Colors.purple),
                    title: Text('Education',
                        style: TextStyle(
                            fontSize: 23.0, fontWeight: FontWeight.w400)),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(10.0),
            child: GestureDetector(
              onTap: () {
                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (BuildContext context) => HomePage(_selfId)));
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 140.0,
                decoration: BoxDecoration(
                    color: Color.fromRGBO(227, 174, 230, 1),
                    borderRadius: BorderRadius.circular(10.0)),
                child: Center(
                  child: ListTile(
                    leading: Icon(Icons.business, color: Colors.purple),
                    title: Text('Business',
                        style: TextStyle(
                            fontSize: 23.0, fontWeight: FontWeight.w400)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
