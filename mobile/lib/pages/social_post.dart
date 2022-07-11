import 'package:flutter/material.dart';

import '../dto/posts.dart';

class SocialPost extends StatelessWidget {
  PostDto post;

  SocialPost({required this.post});

  String formatHeaderContent() {
    return "was at ${post.outingStep.placeDto.name} at ${post.postedAt}";
  }

  Widget buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile photo
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
            image: DecorationImage(
                image: NetworkImage(
                    post.user.imageLink
                )
            )
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.user.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              formatHeaderContent(),
            )
          ],
        ),
        const Icon(Icons.menu),
      ]
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
      // TODO: Add social info, unless we don't want that, idk
      children: [
        // View itinerary
        // TODO: Actually view the itinerary.
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(
            Icons.remove_red_eye_outlined
          ),
          label: const Text("View Itinerary"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildHeader(),
        buildPicture(),
        buildContent(),
      ],
    );
  }
}

