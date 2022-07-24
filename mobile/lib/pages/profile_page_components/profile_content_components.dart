import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mobile/dto/posts.dart';
import 'package:mobile/dto/review.dart';
import 'package:mobile/pages/place_profile_page.dart';
import 'package:mobile/pages/profile_page_components/profile_skeleton.dart';
import 'package:mobile/pages/social_feed.dart';
import 'package:mobile/services/posts.dart';
import 'package:mobile/services/reviews.dart';
import 'package:mobile/utils/errors.dart';

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
    return ReviewFeed(user: user);
  }

  static WidgetValueBuilder getOtherProfileContentBuilder() {
    return (BuildContext context, UserProfileDto user) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user.imageLink),
      );
    };
  }
}

class ReviewFeed extends StatefulWidget {
  final UserProfileDto user;
  const ReviewFeed({
    Key? key,
    required this.user
  }) : super(key: key);

  @override
  State<ReviewFeed> createState() => _ReviewFeedState();
}

class _ReviewFeedState extends State<ReviewFeed> {

  final reviewService = Get.find<ReviewService>();

  static const int startingPageNumber = 0;
  final _pagingController = PagingController<int, ReviewDto>(
    firstPageKey: startingPageNumber
  );

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      loadReviews(pageKey);
    });
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void loadReviews(int pageKey) async {
    final response = await reviewService.getReviewsByUser(widget.user.id, pageKey);
    if (response.isOk) {
      if (response.body!.isEmpty) {
        _pagingController.appendLastPage(response.body!);
      } else {
        _pagingController.appendPage(response.body!, pageKey + 1);
      }
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: PagedListView.separated(
        pagingController: _pagingController,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        builderDelegate: PagedChildBuilderDelegate<ReviewDto>(
          itemBuilder: (context, review, index) => ReviewCard(review: review),
          noMoreItemsIndicatorBuilder: noMoreItemsIndicator
        ),
      ),
    );
  }

  Widget noMoreItemsIndicator(BuildContext context) {
    return const Center(
      child: Text("No more reviews"),
    );
  }
}


class ReviewCard extends StatelessWidget {

  final ReviewDto review;

  const ReviewCard({
    Key? key,
    required this.review
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildReviewListTile(context, review);
  }

  Widget buildReviewListTile(BuildContext context, ReviewDto review) {
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

}