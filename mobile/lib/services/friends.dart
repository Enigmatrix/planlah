import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/services/base_connect.dart';

class FriendService extends BaseConnect {
  Future<Response<List<UserSummaryDto>?>> getFriends(int pageNumber) async {
    var query = {
      "page": pageNumber.toString()
    };
    return await get(
      "/friends/all",
      query: query,
      decoder: decoderForList(UserSummaryDto.fromJson)
    );
  }
}