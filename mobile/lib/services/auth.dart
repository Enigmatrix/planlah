import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';

// based off https://petercoding.com/firebase/2021/05/24/using-google-sign-in-with-firebase-in-flutter/

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final Rxn<User?> user = Rxn<User?>(FirebaseAuth.instance.currentUser);

  @override
  void onReady() async {
    // fire user changes
    user.bindStream(_auth.userChanges());

    super.onReady();
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
