import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/dev_panel.dart';
import 'package:mobile/services/auth.dart';

import '../services/config.dart';
import '../services/user.dart';

// based off https://petercoding.com/firebase/2021/05/24/using-google-sign-in-with-firebase-in-flutter/

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text("planlah"),
          actions: [
            ...devPanelAction()
          ]
        ),
        body: Column(
          children: [
            Expanded(
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 0.7 * size.width,
                          height: 0.7 * size.width,
                          child: SvgPicture.asset("assets/logo.svg"),
                        ),
                        const Text("planlah!", style: TextStyle(fontSize: 44.0)),
                      ]
                  ),
                )
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48.0),
              child: GoogleSignIn(),
            )
          ],
        )
    );
  }
}

class GoogleSignIn extends StatefulWidget {
  const GoogleSignIn({Key? key}) : super(key: key);

  @override
  GoogleSignInState createState() => GoogleSignInState();
}

class GoogleSignInState extends State<GoogleSignIn> {
  bool isLoading = false;
  late AuthService auth;
  late UserService userSvc;

  @override
  void initState() {
    super.initState();
    auth = Get.find();
    userSvc = Get.find();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

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
                  if (user != null) {
                    log(user.uid);

                    final info = await userSvc.getInfo();
                    if (info.hasError) {
                      // this means no user in the database, so add one
                      await Get.offAndToNamed('signUp');
                    } else {
                      // this means the user already has an account,
                      // either but install+uninstall or from another device
                      await Get.offAndToNamed('home');
                    }

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
