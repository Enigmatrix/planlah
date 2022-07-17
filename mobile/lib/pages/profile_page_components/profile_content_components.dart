import 'package:flutter/material.dart';
import 'package:mobile/pages/profile_page_components/profile_skeleton.dart';

import '../../dto/user.dart';

class ProfileContent {

  static const numTabs = 2;

  static WidgetValueBuilder getProfileContentBuilder(

      ) {
    return (BuildContext context, UserProfileDto user) {
      return DefaultTabController(
          length: numTabs,
          child: buildTabBar()
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
          buildTabChild(),
          buildTabChild(),
        ]
    );
  }

  static Widget buildTabChild() {
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