import 'package:get/get.dart';
import 'package:mobile/dto/posts.dart';
import 'package:mobile/services/base_connect.dart';

class PostService extends BaseConnect {
  Future<Response<List<PostDto>?>> getPosts(int pageNumber) async {
    var query = {
      "page": pageNumber.toString()
    };
    return await get(
      "/posts/all",
      query: query,
      decoder: decoderForList(PostDto.fromJson)
    );
  }
}