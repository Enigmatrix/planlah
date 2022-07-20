import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/social_post.dart';
import 'package:mobile/services/posts.dart';
import 'package:mobile/utils/errors.dart';

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


  int pageNumber = 0;
  List<PostDto> posts = [];

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  void loadPosts() async {
    final response = await widget.loadPosts(pageNumber);
    if (response.isOk) {
      setState(() {
        posts.addAll(response.body!);
      });
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, response);
    }
  }

  @override
  Widget build(BuildContext context) {
      return ListView.builder(
          itemCount: posts.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return SocialPost(post: posts[index]);
          }
    );
  }
}
