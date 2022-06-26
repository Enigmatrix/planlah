import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/dto/outing.dart';
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


  final groupService = Get.find<GroupService>();

  // Replace with actual retrieving from database in the future
  // The list of all groups by which we filter on
  late List<GroupSummaryDto> allGroupDtos = [];
  late List<GroupSummaryDto> currentGroupDtos = [];
  late List<ChatGroup> allGroups = [];
  // What's actually displayed
  late List<ChatGroup> groups = [];

  @override
  initState() {
    super.initState();

    groupService.getGroup().then((value) {
      setState(() {
        print(value.body!);
        allGroupDtos = value.body!;
        currentGroupDtos = allGroupDtos;
      });
    });
    // groups = allGroups;
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
          buildGroups(currentGroupDtos)
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
    List<GroupSummaryDto> results = [];
    if (filter.isEmpty) {
      results = allGroupDtos;
    } else {
      results = allGroupDtos.where((group) => group.name.toLowerCase().contains(filter.toLowerCase())).toList();
    }

    setState(() {
      currentGroupDtos = results;
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

  Widget buildGroups(List<GroupSummaryDto> groups) {
    return ListView.builder(
      itemCount: groups.length,
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 16),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        // To add page to redirect to
        return GroupDisplay(
            chatGroup: groups[index],
        );
      },
    );
  }
}
