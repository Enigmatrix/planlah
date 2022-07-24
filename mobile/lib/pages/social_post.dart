import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/outing_page.dart';
import 'package:mobile/pages/profile_page.dart';
import 'package:mobile/services/outing.dart';
import 'package:mobile/utils/time.dart';

import '../dto/posts.dart';

class SocialPost extends StatelessWidget {
  PostDto post;

  final outingSvc = Get.find<OutingService>();

  SocialPost({required this.post});

  String formatHeaderContent() {
    return "was at ${post.outingStep.place.name} on ${TimeUtil.formatDateTimeForSocialPost(post.postedAt)}";
  }

  Widget buildHeader() {
    return ListTile(
      leading: InkWell(
        onTap: () {
          Get.to(() => ProfilePage(userId: post.user.id));
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
              image: DecorationImage(image: NetworkImage(post.user.imageLink))),
        ),
      ),
      title:
          // Profile photo
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.user.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            formatHeaderContent(),
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
      trailing: const Icon(Icons.menu),
    );
  }

  Widget buildPicture() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            post.imageLink,
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget buildContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final outingId = post.outingStep.outingId;
            final resp = await outingSvc.getOuting(outingId);
            if (resp.isOk) {
              final outing = resp.body!;
              Get.to(() => OutingPage(outing: outing, isActive: false));
            } else {
              log(resp.bodyString!);
            }
          },
          icon: const Icon(Icons.remove_red_eye_outlined),
          label: Text("View Outing"),
        ),
      ],
    );
  }

  Widget buildText() {
    return Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.all(16.0),
      child: Text(post.text),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildHeader(),
          buildText(),
          buildPicture(),
          buildContent(),
        ],
      ),
    );
  }
}
