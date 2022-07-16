import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/services/group.dart';

import '../dto/user.dart';

class JioFriendsToGroupWidget extends StatefulWidget {
  final int groupId;
  const JioFriendsToGroupWidget({
    Key? key,
    required this.groupId
  }) : super(key: key);

  @override
  State<JioFriendsToGroupWidget> createState() => _JioFriendsToGroupWidgetState();
}

class _JioFriendsToGroupWidgetState extends State<JioFriendsToGroupWidget> {

  final groupService = Get.find<GroupService>();

  int page = 0;
  // List of potential users to jio to the group
  List<UserSummaryDto> users = [];


  @override
  void initState() {
    super.initState();
    loadUsers(widget.groupId, page);
  }

  loadUsers(int groupId, int newPage) async {
    var response = await groupService.getFriendsToJio(groupId, newPage);
    setState(() {
      if (response.isOk) {
        users = response.body!;
      }
      page = newPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Jio your friends to this group!"),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: buildJioTile
                )
            ),
            buildNavigationBar(),
          ],
        ),
      )
    );
  }

  Widget buildNavigationBar() {
    return ButtonBar(
      alignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        buildPreviousButton(),
        buildNextButton(),
      ],
    );
  }

  Widget buildPreviousButton() {
    var ret;
    if (page > 0) {
      ret = IconButton(
          onPressed: page <= 0 ? null : () async {
            await loadUsers(widget.groupId, page - 1);
          },
          icon: const Icon(Icons.arrow_back)
      );
    } else {
      ret = const SizedBox.shrink();
    }
    return ret;
  }

  Widget buildNextButton() {
    var ret;
    if (users.isNotEmpty) {
      ret = IconButton(
          onPressed: users.isEmpty ? null : () async {
            await loadUsers(widget.groupId, page + 1);
          },
          icon: const Icon(Icons.arrow_forward)
      );
    } else {
      ret = const SizedBox.shrink();
    }
    return ret;
  }

  Widget buildJioTile(BuildContext context, int index) {
    UserSummaryDto user = users[index];
    return ListTile(
      onTap: () {
        jioToGroup(context, user.id);
      },
      leading: Hero(
        tag: user.username,
        child: CircleAvatar(
          backgroundImage: NetworkImage(user.imageLink),
        ),
      ),
      title: Text(
        user.name,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void jioToGroup(BuildContext context, int userId) async {
    var response = await groupService.jio(userId, widget.groupId);
    if (response.hasError) {
      showErrorSnackbar(context);
    }
    loadUsers(widget.groupId, page);
  }

  void showErrorSnackbar(BuildContext context) {
    SnackBar snackBar = const SnackBar(
        content: Text("There was an error jioing your friend!"),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1)
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
