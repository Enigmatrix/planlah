import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/groups/pages/groups_page.dart';
import 'package:mobile/pages/profile.dart';
import 'package:mobile/pages/social_feed.dart';
import 'package:mobile/services/auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageWidgetState();


}

class _HomePageWidgetState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    SocialFeedPage(),
    GroupsPage(),
    ProfilePage()
  ];

  var currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("planlah"),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.group_add_outlined),
            tooltip: "Create new group",
          )
        ],
      ),
      body: Center(
          child: _pages.elementAt(_selectedIndex)
      ),
      bottomNavigationBar: BottomNavigationBar(
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
              icon: Icon(Icons.settings),
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





