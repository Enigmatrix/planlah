import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/pages/friend_components.dart';
import 'package:mobile/pages/profile_page.dart';
import 'package:mobile/services/friends.dart';
import 'package:mobile/services/session.dart';
import 'package:mobile/utils/errors.dart';
import 'package:mobile/widgets/wait_widget.dart';

import '../services/user.dart';
import 'friend_requests_page.dart';

class FriendsPage extends StatefulWidget {

  final int userId;

  const FriendsPage({
    Key? key,
    required this.userId
  }) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {

  // TODO: Use a StreamBuilder to refresh and paginate the friend list

  final friendService = Get.find<FriendService>();

  List<UserSummaryDto> _friends = [];
  StreamSubscription? friendRequestSubscriber;

  // For pagination
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    final sess = Get.find<SessionService>();
    _loadFriends();
    friendRequestSubscriber = sess.anyFriendRequest(widget.userId).listen((event) {
      log("UPDATE FRIEND REQUEST");
      _loadFriends();
    });
  }

  @override
  void dispose() {
    friendRequestSubscriber?.cancel();
    super.dispose();
  }

  void _loadFriends() async {
    var response = await friendService.getFriends(currentPage);
    if (response.isOk) {
      setState(() {
        _friends = response.body!;
      });
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, response);
    }
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
    // TODO: Fix with sockets
    var result = await Get.to(() => FriendRequestPage(userId: widget.userId));
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
      itemBuilder: (context, index) => FriendComponents.buildFriendTile(context, _friends[index], () => ProfilePage(userId: _friends[index].id)),
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
          showResults(context);
        },
        icon: const Icon(Icons.search)
      ),
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
    if (query == "") {
      return buildNoResults();
    }
    return FutureBuilder(
      future: userService.searchForFriends(0, query),
      builder: (BuildContext context, AsyncSnapshot<Response<List<UserSummaryDto>?>> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.hasError) {
            return buildErrorResults();
          } else {
            results = snapshot.data!.body!;
            if (results.isEmpty) {
              return buildNoResults();
            } else {
              return buildSearchResults();
            }
          }
        } else {
          return waitWidget();
        }
      }
    );
  }

  Widget buildErrorResults() {
    return const Center(child: Text("Encountered an error while searching"));
  }

  Widget buildNoResults() {
    return const Center(child: Text("No data found"));
  }

  Widget buildSearchResults() {
    return ListView.builder(
        itemCount: results.length,
        itemBuilder: buildUserListTile
    );
  }


  void searchFriends() async {
    Response<List<UserSummaryDto>?> response = await userService.searchForFriends(0, query);
    if (response.isOk) {
      results = response.body!;
    } else {
      results = [];
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
                  sendFriendRequest(context, user);
                },
                icon: const Icon(Icons.person_add)
            )
          ],
        ),
      ),
    );
  }

  void sendFriendRequest(BuildContext context, UserSummaryDto user) async {
    Response<dynamic> response = await friendService.sendFriendRequest(user.id);
    String status;
    if (response.isOk) {
      // Response is a String if ok
      status = response.body!;
    } else {
      // Response is a ErrorMessage if not
      status = response.body!["message"];
    }
    triggerSnackBar(context, status);
  }

  void triggerSnackBar(BuildContext context, String status) {
    SnackBar snackBar;
    switch (status) {
      case pending:
        snackBar = const SnackBar(
          content: Text("Your friend request has been sent!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1)
        );
        break;
      case friendReqExists:
        snackBar = const SnackBar(
          content: Text("Already sent a friend request!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1)
        );
        break;
      case isSameUser:
        snackBar = const SnackBar(
          content: Text("Same user!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1)
        );
        break;
      default:
        snackBar = const SnackBar(
          content: Text("Something went wrong!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        );
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
