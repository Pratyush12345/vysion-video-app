import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'User.dart';

class FireBaseAuth {
  FireBaseAuth();
  static FireBaseAuth instance = FireBaseAuth._();
  FireBaseAuth._();
  SharedPreferences _pref;
  FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  User _userFromFirebaseUser (FirebaseUser user){
    return user!=null? User(uid: user.uid, name: user.displayName, email: user.email, photoUrl: user.photoUrl): null;
  }
  Stream<User> get user{
    return _auth.onAuthStateChanged
    .map((FirebaseUser user)=>_userFromFirebaseUser(user));
  } 

  Future<User> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    print("signed in " + user.email);
    return _userFromFirebaseUser(user);
  }

  Future<User> signInWithEmail(String email, String password) async {
    AuthResult authResult = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    FirebaseUser user =  authResult.user;
    print("signed in " + user.email);
    return _userFromFirebaseUser(user);
  }

  Future<User> signUpWithEmail( String username, String email, String password) async {
        try{
            _pref = await SharedPreferences.getInstance();
            _pref.setString('signUpUserName',username);
            AuthResult authResult = await _auth.createUserWithEmailAndPassword(
           email: email, password: password);
           print('////////////${authResult.user.uid}>>>>>>>>>>>>');
           FirebaseUser user = authResult.user;
           print('??????????//////$user>>>>>>>');
           print('signed up ' + email);
            return _userFromFirebaseUser(user);
        }catch(e){
            return null;
        }
  
  }

  Future logout() async {
    try{
      _pref = await SharedPreferences.getInstance();
            //_pref.remove('signUpUserName');
      return await _auth.signOut().then((onValue) {
      _googleSignIn.signOut();
    });
    }catch(e){
      print(e.toString());
      return null;
    }
  }

}
