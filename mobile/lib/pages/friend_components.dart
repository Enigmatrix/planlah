import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../dto/user.dart';

typedef PageBuilder = Widget Function();

class FriendComponents {
  static Widget buildFriendTile(BuildContext context, UserSummaryDto _friend, PageBuilder page) {
    return ListTile(
      onTap: () {
        Get.to(() => page());
      },
      leading: Hero(
        tag: _friend.username,
        child: CircleAvatar(
          backgroundImage: NetworkImage(_friend.imageLink),
        ),
      ),
      title: Text(
        _friend.name,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}