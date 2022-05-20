import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/services/auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final AuthService auth = Get.find();

    return Scaffold(
        appBar: AppBar(title: const Text("Home")),
        body: ListView(
            children: [
          ElevatedButton(
              onPressed: () async {
                await auth.signOutFromGoogle();
                await Get.offAndToNamed('signIn');
              },
              child: const Text("LOG OUT")),
          ElevatedButton(
              onPressed: () async {
                log((await auth.user.value?.getIdToken()).toString());
              },
              child: const Text("PRINT TOKEN"))
        ]));
  }
}
