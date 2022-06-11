import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/pages/social_post.dart';

import '../model/group.dart';

class SocialFeedPage extends StatelessWidget {
  final List<GroupInfo> groups;

  const SocialFeedPage({required this.groups});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: groups.length,
          itemBuilder: (context, index) {
            return SocialPost(
                group: groups[index]
            );
          }
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(
    //
    //   ),
    //   body: ,
    // );
  }
}
