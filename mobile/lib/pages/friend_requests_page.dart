import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/friends.dart';
import 'package:mobile/services/friends.dart';

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
    setState(() {
      _friendRequests = response.body!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friend Requests"),
        actions: <Widget>[

        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(6),
        itemCount: _friendRequests.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: buildFriendRequestGridViewItem,
      )
    );
  }

  Widget buildFriendRequestGridViewItem(BuildContext context, int index) {
    var friendRequest = _friendRequests[index];
    var UserSummaryDto = friendRequest.from;
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
                    backgroundImage: NetworkImage(UserSummaryDto.imageLink),
                  )
              ),
              Text(UserSummaryDto.name),
              Text(UserSummaryDto.username),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {},
                    child: const Icon(Icons.check_sharp),
                  ),
                  ElevatedButton(
                    onPressed: () {},
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

}
