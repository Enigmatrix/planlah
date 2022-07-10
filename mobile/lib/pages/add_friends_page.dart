import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          // Potentially hacky way to force refresh of previous page?
          onPressed: () {
            Get.back(result: "refresh");
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
    );
  }
}
