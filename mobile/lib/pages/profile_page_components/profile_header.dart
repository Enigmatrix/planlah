import 'package:flutter/material.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/pages/profile_page_components/profile_skeleton.dart';


class ProfileHeader {

  static WidgetValueBuilder getOtherProfileHeaderBuilder() {
    return (BuildContext context, UserSummaryDto user) {
      return Column(
        children: <Widget>[
          ProfileHeaderWidget(userSummaryDto: user),
          IconButton(
              onPressed: () {
                // TODO: To redirect to the DM
              },
              icon: const Icon(Icons.mail)
          )
        ],
      );
    };
  }

  static WidgetValueBuilder getUserProfileHeaderBuilder() {
    return (BuildContext context, UserSummaryDto user) {
      return ProfileHeaderWidget(userSummaryDto: user);
    };
  }

}

/// Common Profile Header used by both user and other.
/// Displays number of posts, reviews and friends.
class ProfileHeaderWidget extends StatefulWidget {

  final UserSummaryDto userSummaryDto;
  const ProfileHeaderWidget({
    Key? key,
    required this.userSummaryDto
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
          // TODO: Implement interfaces to get data for number of posts, reviews and friends
          buildButton(context, "32", "Posts", () { }),
          buildDivider(),
          buildButton(context, "64", "Reviews", () { }),
          buildDivider(),
          buildButton(context, "128", "Friends", () { }),
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
