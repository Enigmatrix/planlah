import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/services/friends.dart';

import '../services/user.dart';
import 'friend_requests_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {

  // TODO: Use a StreamBuilder to refresh and paginate the friend list

  final friendService = Get.find<FriendService>();

  List<UserSummaryDto> _friends = [];

  // For pagination
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends() async {
    var response = await friendService.getFriends(currentPage);
    setState(() {
      _friends = response.body!;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_friends.isEmpty) {
      content = buildNoFriendsWidget();
    } else {
      content = buildFriendsList();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
        actions: <Widget>[
          buildAddFriendButton(),
          buildFriendRequestsButton(),
        ],
      ),
      body: content,
    );
  }
  
  Widget buildFriendRequestsButton() {
    return ElevatedButton(
      onPressed: () {
        _navigateAndRefresh(context);
      },
      child: const Icon(Icons.person_pin_sharp),
    );
  }

  
  Widget buildAddFriendButton() {
    return IconButton(
        onPressed: () {
          showSearch(
              context: context,
              delegate: FriendSearch()
          );
        },
        icon: const Icon(Icons.search)
    );
  }
  
  void _navigateAndRefresh(BuildContext context) async {
    var result = await Get.to(() => const FriendRequestPage());
    if (result != null) {
      _loadFriends();
    }
  }

  Widget buildNoFriendsWidget() {
    return const Center(
      child: Text("It seems you have no friends :("),
    );
  }

  Widget buildFriendsList() {
    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: buildFriendTile,
    );
  }

  Widget buildFriendTile(BuildContext context, int index) {
    var _friend = _friends[index];

    return ListTile(
      // TODO: Friend profile page
      leading: Hero(
        tag: index,
        child: CircleAvatar(
          backgroundImage: NetworkImage(_friend.imageLink),
        ),
      ),
      title: Text(
        _friend.name,
      ),

    );
  }
}

class FriendSearch extends SearchDelegate<UserSummaryDto> {
  final userService = Get.find<UserService>();
  final friendService = Get.find<FriendService>();
  List<UserSummaryDto> results = [];

  static const pending = "pending";
  static const isSameUser = "users are the same";
  static const friendReqExists = "friend request exists";


  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            query = "";
          },
          icon: const Icon(Icons.clear)
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () {
          close(context, UserSummaryDto(55, "Jotham", "Jotham", "https://supermariorun.com/assets/img/stage/mario03.png"));
        },
        icon: const Icon(Icons.arrow_back)
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: Page number???
    userService.searchForFriends(0, query).then((response) => {
      if (response.isOk) {
        results = response.body!
      } else {
        results = []
      }
    });
    if (results.isEmpty) {
      return const Center(child: Text("No results"));
    } else {
      return ListView.builder(
          itemCount: results.length,
          itemBuilder: buildUserListTile
      );
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  Widget buildUserListTile(BuildContext context, int index) {
    UserSummaryDto user = results[index];
    return ListTile(
      onTap: () {
        showDialog(context: context, builder: (context) => buildUserRequestDialog(context, user));
      },
      leading: buildUserAvatar(user),
      title: Text(user.username),
    );
  }

  Widget buildUserRequestDialog(BuildContext context, UserSummaryDto user) {
    return Dialog(
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            buildUserAvatar(user),
            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(user.username),
            IconButton(
                onPressed: () {
                  sendFriendRequest(user);
                },
                icon: const Icon(Icons.person_add)
            )
          ],
        ),
      ),
    );
  }

  void sendFriendRequest(UserSummaryDto user) async {
    Response<dynamic> response = await friendService.sendFriendRequest(user.id);
    String status;

    if (response.isOk) {
      // Response is a String if ok
      status = response.body!;
    } else {
      // Response is a ErrorMessage if not
      status = response.body!["message"];
    }

    triggerSnackBar(status);
  }

  void triggerSnackBar(String status) {
    // TODO: Fix snack bar not showing again after first appearance
    switch (status) {
      case pending:
        Get.snackbar(
          "Success",
          "Your friend request has been sent!",
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM
        ).show().then((value) => Get.closeAllSnackbars());
        break;
      case friendReqExists:
        Get.snackbar(
          "Error",
          "Already sent a friend request",
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM
        ).show().then((value) => Get.closeAllSnackbars());
        break;
      case isSameUser:
        Get.snackbar(
            "Error",
            "Same user",
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM
        ).show().then((value) => Get.closeAllSnackbars());
        break;
      default:
        return;
    }
  }

  Widget buildUserAvatar(UserSummaryDto user) {
    return Hero(
      tag: user.id,
      child: CircleAvatar(
        backgroundImage: NetworkImage(user.imageLink),
      ),
    );
  }

}
