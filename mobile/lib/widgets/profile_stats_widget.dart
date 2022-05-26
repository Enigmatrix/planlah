import 'package:flutter/material.dart';

class ProfileStatsWidget extends StatelessWidget {
  final Map user;

  const ProfileStatsWidget({
    Key? key,
    required this.user
}): super(key: key);

  @override
  Widget build(BuildContext context) => IntrinsicHeight(  // IntrinsicHeight gives the Vertical Dividers their appearance
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        buildButton(context, user["reviews"], "Reviews"),
          buildDivider(),
          buildButton(context, user["following"], "Following"),
          buildDivider(),
          buildButton(context, user["followers"], "Followers"),
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