import 'package:flutter/material.dart';

import '../model/user.dart';

class ProfileStatsWidget extends StatelessWidget {
  final UserInfo user;

  const ProfileStatsWidget({
    Key? key,
    required this.user
}): super(key: key);

  @override
  Widget build(BuildContext context) => IntrinsicHeight(  // IntrinsicHeight gives the Vertical Dividers their appearance
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // TODO: Hard code for now...
        buildButton(context, "420", "Reviews"),
          buildDivider(),
          buildButton(context, "784", "Following"),
          buildDivider(),
          buildButton(context, "3.7m", "Followers"),
      ],
    )
  );

  Widget buildDivider() => const VerticalDivider();

  Widget buildButton(BuildContext context, String value, String label) =>
      MaterialButton(
        padding: const EdgeInsets.symmetric(vertical: 4),
        onPressed: () {},
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