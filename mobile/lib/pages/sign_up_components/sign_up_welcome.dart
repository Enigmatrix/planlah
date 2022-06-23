import 'package:flutter/material.dart';

class SignUpWelcome extends StatelessWidget {
  const SignUpWelcome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Image.asset("assets/undraw_Mobile_login_re_9ntv.png"),
        const Text(
          "Welcome to PlanLah!",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 30, color: Colors.black),
        ),
        const Text(
          "Create an account, it's free",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
