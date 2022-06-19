import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/services/auth.dart';
import 'package:mobile/services/base_connect.dart';
import 'package:mobile/services/config.dart';
import 'package:mobile/services/user.dart';

List<Widget> devPanelAction() {
  final config = Get.find<Config>();
  return !config.isDev() ? [] : [IconButton(onPressed: () async {
    await Get.toNamed('dev_panel');
  }, icon: const Icon(Icons.developer_mode))];
}

class DevPanelPage extends StatefulWidget {
  @override
  State<DevPanelPage> createState() => _DevPanelPageState();
}

class _DevPanelPageState extends State<DevPanelPage> {
  late AuthService auth;
  late UserService user;

  @override
  void initState() {
    super.initState();
    auth = Get.find<AuthService>();
    user = Get.find<UserService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("planlah Dev Panel")
      ),
      body: Column(
        children: [
          authWidget()
        ],
      ),
    );
  }

  Widget authWidget() {
    return auth.user.value == null ? authLoginWidget() : authInfoWidget();
  }

  Widget authLoginWidget() {
    return const Card(
      child: ListTile(
        title: Text("Not logged in"),
        trailing: Icon(Icons.question_mark),
      )
    );
  }

  Widget authInfoWidget() {
    return Card(
        child: Column(
          children: [
            ListTile(
              title: Text("FID: ${auth.user.value!.uid}"),
              trailing: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await auth.logout();
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text("Firebase Token"),
              trailing: ElevatedButton(
                  onPressed: () async {
                    final token = await auth.user.value!.getIdToken();
                    await user.getInfo();
                    log(token);
                    log(BaseConnect.token!);
                  },
                  child: const Text("PRINT")
              ),
            ),
          ]
        )
    );
  }
}