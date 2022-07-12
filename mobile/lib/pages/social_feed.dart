import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/social_post.dart';
import 'package:mobile/services/posts.dart';

import '../dto/posts.dart';

class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({Key? key}) : super(key: key);

  @override
  State<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {

  final postService = Get.find<PostService>();

  int pageNumber = 0;
  List<PostDto> posts = [];

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  void loadPosts() async {
    Response<List<PostDto>?> response = await postService.getPosts(pageNumber);
    if (response.isOk) {
      setState(() {
        posts.addAll(response.body!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feed"),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return SocialPost(post: posts[index]);
        }
      ),
    );
  }
}
