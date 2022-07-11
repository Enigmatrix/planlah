import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../model/review_info.dart';

/// A widget used to display the group's activities
/// Used by social post and review post at the moment

class ReviewWidget extends StatelessWidget {
  final ReviewInfo reviewInfo;

  const ReviewWidget({required this.reviewInfo});

  @override
  Widget build(BuildContext context) {
    String description = "was at ${reviewInfo.location.name}";
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
                image: DecorationImage(
                    image: NetworkImage(reviewInfo.user.imageLink)
                )
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reviewInfo.user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(description)
              ],
            ),
            const Icon(Icons.menu),
          ],
        ),
      ),
      Container(
        height: 400,
        decoration: BoxDecoration(
            image: DecorationImage(
          image: NetworkImage(
            reviewInfo.location.imageUrl,
          ),
          fit: BoxFit.cover,
        )),
      ),
    RatingBar.builder(
      initialRating: 5,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: (rating) {
        print(rating);
      },
    ),
    RichText(
      text: TextSpan(
          text: reviewInfo.content
        ),
      )
    ]);
  }
}
