
import 'package:flutter/material.dart';

import 'Messages.dart';

class SmallMessages extends ChangeNotifier{
 
 List<Messages> allSmallMessages=[];

 void addSmallMessages(String text, String id) async{
 allSmallMessages.add(Messages(text,id));
 notifyListeners();
 }
}