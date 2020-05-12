import 'package:firebase_database/firebase_database.dart';

class User{
  String uid;
  String name;
  String email;
  String photoUrl;
  User({this.uid, this.name, this.email, this.photoUrl});
  
  User.fromSnapShot(DataSnapshot snapshot):
  name=snapshot.value['Name'],
  photoUrl=snapshot.value['PhotoUrl'];

}