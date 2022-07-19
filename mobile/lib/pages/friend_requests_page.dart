import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/friends.dart';
import 'package:mobile/services/friends.dart';
import 'package:mobile/utils/errors.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({Key? key}) : super(key: key);

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {

  final friendService = Get.find<FriendService>();

  List<FriendRequestDto> _friendRequests = [];

  int pageNumber = 0;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  void _loadFriendRequests() async {
    var response = await friendService.getFriendRequests(pageNumber);
    if (response.isOk) {
      setState(() {
        _friendRequests = response.body!;
      });
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friend Requests"),
        leading: IconButton(
          // Potentially hacky way to force refresh of previous page?
          onPressed: () {
            Get.back(result: "refresh");
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: <Widget>[

        ],
      ),
      body: buildContent()
    );
  }

  Widget buildContent() {
    Widget content;
    if (_friendRequests.length == 0) {
      content = const Center(
        child: Text(
          "You currently have no friend requests"
        ),
      );
    } else {
      content = buildGridView();
    }
    return content;
  }

  Widget buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(6),
      itemCount: _friendRequests.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemBuilder: buildFriendRequestGridViewItem,
    );
  }

  Widget buildFriendRequestGridViewItem(BuildContext context, int index) {
    var friendRequest = _friendRequests[index];
    var userSummaryDto = friendRequest.from;
    return GridTile(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[800]!.withOpacity(0.2)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Hero(
                  tag: index,
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(userSummaryDto.imageLink),
                  )
              ),
              Text(userSummaryDto.name),
              Text(userSummaryDto.username),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => approveFriendRequest(userSummaryDto.id),
                    child: const Icon(Icons.check_sharp),
                  ),
                  ElevatedButton(
                    onPressed: () => rejectFriendRequest(userSummaryDto.id),
                    child: const Icon(Icons.highlight_remove),
                  ),
                ],
              )
            ],
          ),
        ),
      )
    );
  }

  void approveFriendRequest(int userId) async {
    final response = await friendService.approveFriendRequest(userId);
    if (response.isOk) {
      _loadFriendRequests();
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, response);
    }
  }

  void rejectFriendRequest(int userId) async {
    final response = await friendService.rejectFriendRequest(userId);
    if (response.isOk) {
      _loadFriendRequests();
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, response);
    }
  }

}
