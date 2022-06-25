import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/pages/chat_page.dart';
import 'package:mobile/services/group.dart';
import 'package:mobile/widgets/group_display_widget.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

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

  // For creating a new group
  String createGroupName = "";
  String createGroupDescription = "";
  final _groupNameKey = GlobalKey<FormFieldState>();
  final _groupDescKey = GlobalKey<FormFieldState>();

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
              createAddGroupButton(context),
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

  Widget createAddGroupButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // Add new group here
        buildCreateGroupDialog(context).show();
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
              "Create New",
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

  AwesomeDialog buildCreateGroupDialog(BuildContext context) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.INFO,
      borderSide: const BorderSide(
        color: Colors.yellow,
        width: 2
      ),
      width: 280,
      buttonsBorderRadius: const BorderRadius.all(
          Radius.circular(2.0)
      ),
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
      body: Column(
        children: <Widget>[
          const Text(
            "Create a new group",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          buildCreateGroupNameTextBox(),
          buildCreateGroupDescTextBox(),
        ],
      )
    );
  }

  final textPadding = const EdgeInsets.only(
    left: 20.0,
    right: 20.0,
    top: 5.0,
    bottom: 5.0,
  );

  Widget buildCreateGroupNameTextBox() {
    return Padding(
      padding: textPadding,
      child: TextFormField(
        key: _groupNameKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Group Name",
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a description for your outing";
          }
          return null;
        },
        onChanged: (value) {
          setState(
                  () {
                createGroupName = value;
              }
          );
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  Widget buildCreateGroupDescTextBox() {
    return Padding(
      padding: textPadding,
      child: TextFormField(
        key: _groupDescKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Group Description",
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a description for your outing";
          }
          return null;
        },
        onChanged: (value) {
          setState(
                  () {
                createGroupDescription = value;
              }
          );
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
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
