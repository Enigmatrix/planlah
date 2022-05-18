import 'package:flutter/material.dart';
import 'package:mobile/pages/sign_in.dart';
import 'package:mobile/services/auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    if (AuthService().currentUser() == null) {}
    return MaterialApp(
        title: 'planlah',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const SignInPage());
  }
}
