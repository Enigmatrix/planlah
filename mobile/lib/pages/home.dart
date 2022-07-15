import 'package:flutter/material.dart';
import 'package:mobile/pages/groups_page.dart';
import 'package:mobile/pages/profile_page.dart';
import 'package:mobile/pages/settings.dart';
import 'package:mobile/pages/social_feed.dart';
import 'package:mobile/pages/friends_page.dart';

import '../dto/user.dart';

class HomePage extends StatefulWidget {

  UserSummaryDto userSummaryDto;
  HomePage({
    Key? key,
    required this.userSummaryDto,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePage> {
  int _selectedIndex = 0;

  var currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  Widget getPage(int index) {
    switch (index) {
      case 0:
        return SocialFeedPage();
      case 1:
        return GroupsPage();
      case 2:
        return FriendsPage();
      case 3:
        return const ProfilePage(userId: -1);
      default:
        return SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: getPage(_selectedIndex)
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: "Feed"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups),
              label: "Groups"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin_sharp),
            label: "Friends",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile"
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber,
        onTap: _onItemTapped,
      ),
    );
  }
}





