import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/groups/pages/chat_page.dart';
import 'package:mobile/services/group.dart';

import '../model/chat_group.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  // Replace with actual retrieving from database in the future
  List<ChatGroup> groups = getChatGroups();
  // Hard code for now
  static List<ChatGroup> getChatGroups() {
    const data = [
      {
        "groupId": "42069",
        "groupName": "Addicted to League",
        "photoUrl": "https://external-preview.redd.it/FTMkIMnMhnqxCtx-8wlu1wzQaH1UFcA9CaZ3TugXviA.png?auto=webp&s=df74aa3b8d84538bc6a8253a47a7677d903861b0",
        "description": "For people addicted to League of Legends"
      },
      {
        "groupId": "10024",
        "groupName": "Addicted to Coca-Cola",
        "photoUrl": "https://www.foodnavigator-asia.com/var/wrbm_gb_food_pharma/storage/images/_aliases/wrbm_large/publications/food-beverage-nutrition/foodnavigator-asia.com/headlines/business/coca-cola-stands-firm-amid-criticism-of-human-rights-violations-in-south-east-asia/8624735-1-eng-GB/Coca-Cola-stands-firm-amid-criticism-of-human-rights-violations-in-South-East-Asia.jpg",
        "description": "For people addicted to Coca-Cola"
      }
    ];

    return data.map<ChatGroup>(ChatGroup.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Your Groups"),
      centerTitle: true,
    ),
    body: Center(
      child: buildGroups(groups)
    ),
  );

  Widget buildGroups(List<ChatGroup> groups) => ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return GestureDetector(
          onTap: () => Get.to(() => const ChatPage(), arguments: group),
          child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(group.photoUrl),
                ),
                title: Text(group.groupName),
                // This should show how many members are online at the moment maybe
                subtitle: const Text("placeholder text"),
              )
          ),
        );
      },
  );
}
