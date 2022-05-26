import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/profile_stats_widget.dart';
import '../widgets/profile_widget.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Obtain user information properly. For now hard code.
    var user = Map();
    user["imagePath"] = "https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcTnmEUzQenIPa5WMSBlVKq2e3R7bEpP656X9XmE6hxfl7DBdZQ0";
    user["name"] = "Maya Hawke";
    user["email"] = "Atheros@unix.com";
    user["reviews"] = "420";
    user["following"] = "784";
    user["followers"] = "3.7m";
    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          ProfileWidget(
            imagePath: user["imagePath"],
            onClicked: () {}
          ),
          // To add padding
          const SizedBox(height: 24),
          buildName(user),
          ProfileStatsWidget(user: user),
        ],
      ),
    );
  }

  Widget buildName(Map user) => Column(
    children: [
      Text(
        user["name"],
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16
        )
      ),
      const SizedBox(height: 4),
      Text(
        user["email"],
        style: const TextStyle(
          color: Colors.grey
        )
      )
    ],
  );
}
