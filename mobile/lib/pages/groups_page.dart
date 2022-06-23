import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/chat_page.dart';
import 'package:mobile/services/group.dart';
import 'package:mobile/widgets/group_display_widget.dart';

import '../model/chat_group.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {

  // Replace with actual retrieving from database in the future
  // The list of all groups by which we filter on
  final List<ChatGroup> allGroups = getChatGroups();
  // What's actually displayed
  late List<ChatGroup> groups;

  @override
  initState() {
    groups = allGroups;
    super.initState();
  }

  // Hard code for now
  static List<ChatGroup> getChatGroups() {
    const data = [
      {
        "groupId": "42069",
        "groupName": "Addicted to League",
        "mostRecentText": "Bel'Veth is OP!",
        "time": "23:59",
        "photoUrl": "https://external-preview.redd.it/FTMkIMnMhnqxCtx-8wlu1wzQaH1UFcA9CaZ3TugXviA.png?auto=webp&s=df74aa3b8d84538bc6a8253a47a7677d903861b0",
        "description": "For people addicted to League of Legends"
      },
      {
        "groupId": "10024",
        "groupName": "Addicted to Coca-Cola",
        "mostRecentText": "Coca-Cola is the number 1 soft drink in the world!",
        "time": "23:54",
        "photoUrl": "https://www.foodnavigator-asia.com/var/wrbm_gb_food_pharma/storage/images/_aliases/wrbm_large/publications/food-beverage-nutrition/foodnavigator-asia.com/headlines/business/coca-cola-stands-firm-amid-criticism-of-human-rights-violations-in-south-east-asia/8624735-1-eng-GB/Coca-Cola-stands-firm-amid-criticism-of-human-rights-violations-in-South-East-Asia.jpg",
        "description": "For people addicted to Coca-Cola"
      },
      {
        "groupId": "12345",
        "groupName": "Addicted to Pepsi-Cola",
        "mostRecentText": "Pepsi-Cola is the worst soft drink in the world!",
        "time": "23:54",
        "photoUrl": "https://thumbs.dreamstime.com/b/can-pepsi-cola-london-uk-june-th-over-plain-white-background-th-june-product-produced-manufactured-pepsico-73246795.jpg",
        "description": "For people who clearly have no taste"
      },
    ];

    return data.map<ChatGroup>(ChatGroup.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildHeader(),
          buildSearchBar(),
          buildGroups(groups)
        ],
      ),
    ),
  );

  Widget buildHeader() {
    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                "Your Groups",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold
                ),
              ),
              createAddGroupButton(),
            ],
          ),
        )
    );
  }

  Widget buildSearchBar() {
    return Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          child: TextField(
            onChanged: (value) => _runFilter(value),
            decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.all(8),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                        color: Colors.grey
                    )
                )
            ),
          ),
        );
  }

  void _runFilter(String filter) {
    List<ChatGroup> results = [];
    if (filter.isEmpty) {
      results = allGroups;
    } else {
      results = allGroups.where((group) => group.groupName.toLowerCase().contains(filter.toLowerCase())).toList();
    }

    setState(() {
      groups = results;
    });
  }

  Widget createAddGroupButton() {
    return InkWell(
      onTap: () {
        // Add new group here
      },
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
        height: 30,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.pink[50]
        ),
        child: Row(
          children: const <Widget>[
            Icon(
              Icons.group_add,
              color: Colors.pink,
              size: 20,
            ),
            SizedBox(
              width: 2,
            ),
            Text(
              "Add New",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildGroups(List<ChatGroup> groups) {
    return ListView.builder(
      itemCount: groups.length,
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 16),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        // To add page to redirect to
        return GroupDisplay(
            chatGroup: groups[index]
        );
      },
    );
  }
}
