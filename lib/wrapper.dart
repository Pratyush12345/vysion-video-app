import 'package:flutter/material.dart';
import 'package:flutter_webrtc_demo/Authentication/welcome_page.dart';
import 'package:flutter_webrtc_demo/screens/FeaturesPage.dart';
import 'package:provider/provider.dart';
import 'Authentication/User.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
   
   final user=Provider.of<User>(context);
   print(user);
   if(user== null)
   return WelcomePage();
   else
   return FeaturesPage(user.email, user.name, user.uid, user.photoUrl);
  }
}