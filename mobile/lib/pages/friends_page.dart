import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/services/friends.dart';

import 'add_friends_page.dart';
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

  static const String ADD = "ADD";
  static const String REQUEST = "REQUEST";

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
        _navigateAndRefresh(context, REQUEST);
      },
      child: const Icon(Icons.person_pin_sharp),
    );
  }

  
  Widget buildAddFriendButton() {
    return ElevatedButton(
        onPressed: () {
          _navigateAndRefresh(context, ADD);
        },
        child: const Icon(Icons.person_add),
    );
  }
  
  void _navigateAndRefresh(BuildContext context, String type) async {
    var result;
    if (type == ADD) {
      result = await Get.to(() => const AddFriendPage());
    } else {
      result = await Get.to(() => const FriendRequestPage());
    }

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
