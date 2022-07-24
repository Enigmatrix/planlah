import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/social_post.dart';
import 'package:mobile/utils/errors.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../dto/posts.dart';

class SocialFeedPage extends StatefulWidget {

  Future<Response<List<PostDto>?>> Function(int page) loadPosts;

  SocialFeedPage({Key? key, required this.loadPosts}) : super(key: key);

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feed"),
      ),
      body: SocialFeed(loadPosts: widget.loadPosts),
    );
  }
}

class SocialFeed extends StatefulWidget {

  Future<Response<List<PostDto>?>> Function(int page) loadPosts;

  SocialFeed({Key? key, required this.loadPosts}) : super(key: key);

  @override
  State<SocialFeed> createState() => _SocialFeedState();
}

class _SocialFeedState extends State<SocialFeed> {

  static const int startingPageNumber = 0;

  final _pagingController = PagingController<int, PostDto>(
      firstPageKey: startingPageNumber
  );

  List<PostDto> posts = [];

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      loadPosts(pageKey);
    });
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  void loadPosts(int pageKey) async {
    final response = await widget.loadPosts(pageKey);
    if (response.isOk) {
      if (response.body!.isEmpty) {
        // This avoids an infinite loading widget when there is nothing else
        // to load.
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
        builderDelegate: PagedChildBuilderDelegate<PostDto>(
          itemBuilder: (context, post, index) => SocialPost(post: post),
          noMoreItemsIndicatorBuilder: noMoreItemsIndicator
        ),
      )
    );
  }

  Widget noMoreItemsIndicator(BuildContext context) {
    return const Center(
      child: Text("No more items"),
    );
  }
}
