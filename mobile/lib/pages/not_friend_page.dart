import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/friends.dart';

/// This page is displayed when the user attempts to visit another user's profile
/// page when they are not friends.
/// A message will be shown to indicate that they aren't friends, and an option
/// to add them as friends.
class NotFriendPage extends StatefulWidget {

  final int userId;
  const NotFriendPage({
    Key? key,
    required this.userId
  }) : super(key: key);

  @override
  State<NotFriendPage> createState() => _NotFriendPageState();
}

class _NotFriendPageState extends State<NotFriendPage> {

  final friendService = Get.find<FriendService>();

  static const pending = "pending";
  static const friendReqExists = "friend request exists";

  void sendFriendRequest(BuildContext context) async {
    Response<dynamic> response = await friendService.sendFriendRequest(widget.userId);
    String status;
    if (response.isOk) {
      // Response is a String if ok
      status = response.body!;
    } else {
      // Response is a ErrorMessage if not
      status = response.body!["message"];
    }
    if (!mounted) return;
    triggerSnackBar(context, status);
  }

  void triggerSnackBar(BuildContext context, String status) {
    SnackBar snackBar;
    switch (status) {
      case pending:
        snackBar = const SnackBar(
            content: Text("Your friend request has been sent!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1)
        );
        break;
      case friendReqExists:
        snackBar = const SnackBar(
            content: Text("Already sent a friend request!"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1)
        );
        break;
      default:
        snackBar = const SnackBar(
          content: Text("Something went wrong!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        );
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const FittedBox(
              fit: BoxFit.fitWidth,
              child: Text("It seems you are not friends on the app")
            ),
            const FittedBox(
              fit: BoxFit.fitWidth,
              child: Text("Add the user as a friend to view his profile")
            ),
            IconButton(
              onPressed: () {
                sendFriendRequest(context);
              },
              icon: const Icon(Icons.person_add)
            ),
          ],
        ),
      ),
    );
  }
}
