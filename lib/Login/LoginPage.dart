import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc_demo/screens/HomePage.dart';
import 'package:flutter_webrtc_demo/src/call_sample/random_string.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoggedIn = false;
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser _user;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  final dbRef= FirebaseDatabase.instance.reference();

  Future<void> _login() async {
    try {
      GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      AuthCredential authCredential = GoogleAuthProvider.getCredential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);
      AuthResult result = await _auth.signInWithCredential(authCredential);

      _user = result.user;
      dbRef.child("Users").child(_user.uid).set({
        "Name": _user.displayName,
        "MessagesId": randomNumeric(10)
      });
      setState(() {
        _isLoggedIn = true;
      });
    } catch (err) {
      print(err);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut().then((onValue) {
      _googleSignIn.signOut();
      setState(() {
        _isLoggedIn = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: _isLoggedIn
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.network(
                        _user.photoUrl,
                        height: 50.0,
                        width: 50.0,
                      ),
                      Text(_user.displayName),
                      Text(_user.email),
                      OutlineButton(
                        onPressed: () {
                          _logout();
                        },
                        child: Text('Logout'),
                      ),
                      OutlineButton(
                          child: Text('Friends and Family'),
                          onPressed: () {
                            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => 
                      
                      HomePage()));
                          })
                    ],
                  )
                : OutlineButton(
                    child: Text('Login With Google'),
                    onPressed: () {
                      _login();
                    })));
  }
}
