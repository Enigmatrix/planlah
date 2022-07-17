import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/pages/group_chat_page.dart';
import 'package:mobile/pages/profile_page_components/profile_skeleton.dart';
import 'package:mobile/services/group.dart';
import 'package:mobile/utils/errors.dart';

import '../../services/user.dart';


class ProfileHeader {

  static WidgetValueBuilder getOtherProfileHeaderBuilder() {
    return (BuildContext context, UserProfileDto user) {
      return Column(
        children: <Widget>[
          ProfileHeaderWidget(userProfile: user),
          IconButton(
              onPressed: () async {
                final groupService = Get.find<GroupService>();
                final userService = Get.find<UserService>();
                var resp = await groupService.createDM(user.id);
                var userInfoResp = await userService.getInfo();
                if (resp.isOk && userInfoResp.isOk) {
                  Get.to(() => GroupChatPage(chatGroup: resp.body!, userProfile: userInfoResp.body!));
                } else {
                  await ErrorManager.showError(context, resp);
                }
              },
              icon: const Icon(Icons.mail)
          )
        ],
      );
    };
  }

  static WidgetValueBuilder getUserProfileHeaderBuilder() {
    return (BuildContext context, UserProfileDto user) {
      return ProfileHeaderWidget(userProfile: user);
    };
  }

}

/// Common Profile Header used by both user and other.
/// Displays number of posts, reviews and friends.
class ProfileHeaderWidget extends StatefulWidget {

  final UserProfileDto userProfile;
  const ProfileHeaderWidget({
    Key? key,
    required this.userProfile
  }) : super(key: key);

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          buildButton(context, widget.userProfile.postCount.toString(), "Posts", () { }),
          buildDivider(),
          buildButton(context, widget.userProfile.reviewCount.toString(), "Reviews", () { }),
          buildDivider(),
          buildButton(context, widget.userProfile.friendCount.toString(), "Friends", () { }),
        ],
      ),
    );
  }

  Widget buildDivider() => const VerticalDivider();

  Widget buildButton(BuildContext context, String value, String label, VoidCallback fn) {
    return MaterialButton(
        padding: const EdgeInsets.symmetric(vertical: 4),
        onPressed: fn,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16
              ),
            ),
            const SizedBox(height: 2),
            Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                )
            )
          ],
        )
    );
  }
}
