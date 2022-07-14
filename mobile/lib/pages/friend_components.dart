import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/profile_page.dart';

import '../dto/user.dart';

class FriendComponents {
  static Widget buildFriendTile(BuildContext context, UserSummaryDto _friend) {
    return ListTile(
      onTap: () {
        Get.to(() => ProfilePage(userId: _friend.id));
      },
      leading: Hero(
        tag: _friend.name,
        child: CircleAvatar(
          backgroundImage: NetworkImage(_friend.imageLink),
        ),
      ),
      title: Text(
        _friend.name,
      ),
    );
  }
}