import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
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

  static const int startingPageNumber = 0;
  final _pagingController = PagingController<int, UserSummaryDto>(
    firstPageKey: startingPageNumber
  );

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      loadFriendsToJio(widget.groupId, pageKey);
    });
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  loadFriendsToJio(int groupId, int pageKey) async {
    var response = await groupService.getFriendsToJio(groupId, pageKey);
    setState(() {
      if (response.isOk) {
        if (response.body!.isEmpty) {
          _pagingController.appendLastPage(response.body!);
        } else {
          _pagingController.appendPage(response.body!, pageKey + 1);
        }
      }
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
                child: PagedListView.separated(
                  pagingController: _pagingController,
                  separatorBuilder: (context, index) => const SizedBox(height: 4.0),
                  builderDelegate: PagedChildBuilderDelegate<UserSummaryDto>(
                    itemBuilder: (context, user, index) => buildJioTile(context, user),
                    noMoreItemsIndicatorBuilder: noMoreItemsIndicator
                  ),
                )
            ),
          ],
        ),
      )
    );
  }

  Widget noMoreItemsIndicator(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget buildJioTile(BuildContext context, UserSummaryDto user) {
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
    _pagingController.refresh();
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
