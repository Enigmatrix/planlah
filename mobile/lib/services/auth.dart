import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

// based off https://petercoding.com/firebase/2021/05/24/using-google-sign-in-with-firebase-in-flutter/

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService() {
    // fire user changes
    _auth.userChanges().forEach((_) {
      notifyListeners();
    });
  }

  User? currentUser() {
    return _auth.currentUser;
  }

  // TODO check if user images are already uploaded
  // https://blog.logrocket.com/how-to-build-chat-application-flutter-firebase/#building-a-basic-ui-for-the-chat-application
  Future<User?> signInWithGoogle() async {
    try {
      var googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount == null) {
        // TODO display this auth exception as a widget
        print("Google sign-in failed!");
        return null;
      }
      var googleSignInAuthentication = await googleSignInAccount.authentication;
      var credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      var userCreds = await _auth.signInWithCredential(credential);

      return userCreds.user;
    } on FirebaseAuthException catch (e) {
      // TODO display this auth exception as a widget
      print(e.message);
      return null;
    }
  }

  Future<void> signOutFromGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
