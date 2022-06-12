import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/services/auth.dart';

// based off https://petercoding.com/firebase/2021/05/24/using-google-sign-in-with-firebase-in-flutter/

class SignInPage extends StatelessWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [GoogleSignIn()])));
  }
}

class GoogleSignIn extends StatefulWidget {
  const GoogleSignIn({Key? key}) : super(key: key);

  @override
  GoogleSignInState createState() => GoogleSignInState();
}

class GoogleSignInState extends State<GoogleSignIn> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // listen: false since we are only calling a method
    final AuthService auth = Get.find();

    return isLoading
        ? const CircularProgressIndicator()
        : SizedBox(
            width: size.width * 0.8,
            child: ElevatedButton.icon(
                icon: Image.asset("./assets/google_logo.png",
                    height: 24, width: 24),
                onPressed: () async {
                  setState(() {
                    isLoading = true;
                  });

                  var user = await auth.signInWithGoogle();
                  print(user);
                  if (user != null) {
                    await Get.offAndToNamed('signUp');
                    return;
                  }

                  setState(() {
                    isLoading = false;
                  });
                },
                label: const Text(
                  "SIGN IN",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.white))),
          );
  }
}
