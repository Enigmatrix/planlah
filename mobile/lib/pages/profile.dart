import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/model/review_info.dart';
import 'package:mobile/model/user.dart';
import 'package:mobile/services/user.dart';
import 'package:mobile/widgets/review_widget.dart';

import '../model/location.dart';
import '../widgets/profile_stats_widget.dart';
import '../widgets/profile_widget.dart';

class ProfilePage extends StatefulWidget {
  UserInfo userInfo;
  ProfilePage({
    Key? key,
    required this.userInfo
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {


  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final userService = Get.find<UserService>();

  UserInfo? userInfo;

  @override
  initState() {
    super.initState();
    setUserInfo();
  }

  void setUserInfo() {
    userService.getInfo().then((value) {
      setState(() {
        userInfo = value.body!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print(userInfo);
    // TODO: Obtain user information properly. For now hard code.
    var user = Map();
    user["reviews"] = "420";
    user["following"] = "784";
    user["followers"] = "3.7m";
    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          ProfileWidget(
              imagePath: widget.userInfo.imageUrl,
              onClicked: () {}
          ),
          // To add padding
          const SizedBox(height: 24),
          buildName(),
          ProfileStatsWidget(user: userInfo!),
          buildReview(
              ReviewInfo(
                user: userInfo!,
                content: "Nice ambience, well presented food and friendly service. Service staff makes good food recommendations and every dish was tasty! This restaurant is unique, not the typical Cantonese restaurant. Highly recommended.",
                location: LocationInfo(
                    imageUrl: "https://images.squarespace-cdn.com/content/v1/5c3eefdb31d4dfcaa782d593/1547793235504-3W9IWWVFND06BOVFW0WS/DSD_8606.JPG?format=1500w",
                    name: "Famous Treasure Restaurant"
                ),
              )
          )
        ],
      ),
    );
  }

  Widget buildName() => Column(
    children: [
      Text(
          widget.userInfo.name,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16
          )
      ),
      const SizedBox(height: 4),
      Text(
          widget.userInfo.username,
          style: const TextStyle(
              color: Colors.grey
          )
      )
    ],
  );

  // Hard coded for now
  Widget buildReview(ReviewInfo review) => Column(
    children: <Widget>[
      ReviewWidget(
        reviewInfo: review,
      )
    ],
  );
}