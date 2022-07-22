import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/posts.dart';
import 'package:mobile/dto/review.dart';
import 'package:mobile/pages/place_profile_page.dart';
import 'package:mobile/pages/profile_page_components/profile_skeleton.dart';
import 'package:mobile/pages/social_feed.dart';
import 'package:mobile/services/posts.dart';
import 'package:mobile/services/reviews.dart';

import '../../dto/user.dart';

class ProfileContent {

  static const numTabs = 2;

  static WidgetValueBuilder getProfileContentBuilder() {
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
                Expanded(child: buildTabBarView(user))
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
  
  static Widget buildTabBarView(UserProfileDto user) {
    return TabBarView(
        children: <Widget>[
          buildPostsTabChild(user),
          buildReviewsTabChild(user),
        ]
    );
  }

  static Future<Response<List<PostDto>?>> Function(int) loadPostsFor(UserProfileDto user) {
    return (int pageNumber) async {
      final postService = Get.find<PostService>();
      return await postService.getPostsByUser(user.id, pageNumber);
    };
  }

  static Widget buildPostsTabChild(UserProfileDto user) {
    return SocialFeed(loadPosts: loadPostsFor(user));
  }

  static Widget buildReviewsTabChild(UserProfileDto user) {
    final reviewService = Get.find<ReviewService>();
    return FutureBuilder<Response<List<ReviewDto>?>>(
      future: (() async => await reviewService.getReviewsByUser(user.id, 0))(),
        builder: (ctx, snap) => !snap.hasData ? CircularProgressIndicator() : ReviewsList(reviews: snap.data!.body!)
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

class ReviewsList extends StatelessWidget {

  ReviewsList({Key? key, required this.reviews}) : super(key: key);

  List<ReviewDto> reviews;

  Widget buildReviewsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: reviews.length,
      itemBuilder: buildReviewListTile,
      separatorBuilder: (context, index) => const SizedBox(height: 4.0),
    );
  }

  Widget buildReviewListTile(BuildContext context, int index) {
    ReviewDto review = reviews[index];
    return Card(
      elevation: 8.0,
      child: ListTile(
        onTap: () {
          showDialog(
              context: context,
              builder: (context) => buildReviewDialog(context, review)
          );
        },
        tileColor: Colors.white,
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
              review.user.imageLink
          ),
        ),
        title: Column(
          children: <Widget>[
            Text(
              review.placeDto.name,
              overflow: TextOverflow.ellipsis,
            ),
            buildRatingBar(review.rating.toDouble()),
            Text(
              review.content,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
      ),
    );
  }

  Widget buildReviewDialog(BuildContext context, ReviewDto review) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              review.user.imageLink
            ),
          ),
          Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // About place
                    CachedNetworkImage(
                        imageUrl: review.placeDto.imageLink
                    ),
                    Text(
                        review.placeDto.name
                    ),
                    Text(
                        review.placeDto.formattedAddress
                    ),
                    buildRatingBar(review.rating.toDouble()),
                    const Divider(),
                    Text(
                      review.content,
                      softWrap: true,
                    ),
                  ],
                ),
              )
          ),
        ],
      ),
    );
  }


  Widget buildRatingBar(double rating) {
    return RatingBarIndicator(
      rating: rating,
      itemCount: PlaceProfilePage.MAX_RATING,
      itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
      direction: Axis.horizontal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildReviewsList();
  }
}