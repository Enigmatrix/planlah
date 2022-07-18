import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/posts.dart';
import 'package:mobile/pages/profile_page_components/profile_skeleton.dart';
import 'package:mobile/pages/social_feed.dart';
import 'package:mobile/services/posts.dart';

import '../../dto/user.dart';

class ProfileContent {

  static const numTabs = 2;

  static WidgetValueBuilder getProfileContentBuilder(

      ) {
    return (BuildContext context, UserProfileDto user) {
      return Expanded(
        child: DefaultTabController(
            length: numTabs,
            child:  Scaffold(
              body: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    buildTabBar(),
                    Expanded(child: buildTabBarView())
                  ],
                ),
              )
        ),
      );
    };
  }

  static TabBar buildTabBar() {
    return const TabBar(
      indicatorColor: Colors.blue,
      labelColor: Colors.blue,
      tabs: <Widget>[
        Tab(
          text: "Posts",
          icon: Icon(Icons.photo_album),
        ),
        Tab(
          text: "Reviews",
          icon: Icon(Icons.reviews),
        )
      ],
    );
  }
  
  static Widget buildTabBarView() {
    return TabBarView(
        children: <Widget>[
          buildPostsTabChild(),
          buildReviewsTabChild(),
        ]
    );
  }


  static Future<Response<List<PostDto>?>> loadPosts(int pageNumber) async {
    final postService = Get.find<PostService>();
    return await postService.getPosts(pageNumber);
  }

  static Widget buildPostsTabChild() {
    return SocialFeed(loadPosts: loadPosts);
  }

  static Widget buildReviewsTabChild() {
    return SafeArea(
        top: false,
        bottom: false,
        // Builder needed to provide a BuildContext inside the NestedScrollView so that

        child: Builder(
          builder: (BuildContext context) {
            return Text("data");
          },
        )
    );
  }

  static WidgetValueBuilder getOtherProfileContentBuilder() {
    return (BuildContext context, UserProfileDto user) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user.imageLink),
      );
    };
  }
}