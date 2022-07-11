import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/group.dart';

class SocialPost extends StatelessWidget {
  GroupInfo group;

  SocialPost({required this.group});

  @override
  Widget build(BuildContext context) {
    String post;
    switch (group.members.length) {
      case 0:
      // TODO: Add gender
      // TODO: Make "__ others clickable"
        post = "by himself";
        break;
      case 1:
        post = "with one other";
        break;
      default:
        post = "with ${group.members.length} others";
        break;
    }
    String description = "is at ${group.currentLocation.name} $post";
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
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
                      image: NetworkImage(group.owner.imageLink)
                  )
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.owner.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description
                  )
                ],
              ),
              const Icon(Icons.menu),
          ]
          ),
        ),
        // Picture
        Container(
          height: 400,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                group.currentLocation.imageUrl,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Statuses
        Row(
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
        )

      ],
    );
  }
}

