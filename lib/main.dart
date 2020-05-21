import 'dart:core';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc_demo/Authentication/welcome_page.dart';
import 'package:flutter_webrtc_demo/Login/LoginPage.dart';
import 'package:flutter_webrtc_demo/screens/HomePage.dart';
import 'package:provider/provider.dart';
import 'Authentication/FirebaseAuth.dart';
import 'Authentication/User.dart';
import 'wrapper.dart';
import 'package:flutter_webrtc_demo/Modal/SmallMessage.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // return MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (BuildContext context)=> SmallMessages()),
    //     StreamProvider<User>.value(value: FireBaseAuth().user)
    //   ],
    //       child: MaterialApp(
    //     home: Wrapper(),
    //     debugShowCheckedModeBanner: false,
    //     theme: ThemeData(
    //       primarySwatch: Colors.blue
    //     )
    //   ),
    // );
    return MaterialApp(
      home: HomePage(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue
        )
    );
  }
}