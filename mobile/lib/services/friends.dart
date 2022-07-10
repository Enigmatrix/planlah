import 'package:get/get.dart';
import 'package:mobile/dto/friends.dart';
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

  Future<Response<List<FriendRequestDto>?>> getFriendRequests(int pageNumber) async {
    var query = {
      "page": pageNumber.toString()
    };
    return await get(
        "/friends/requests/all",
        query: query,
        decoder: decoderForList(FriendRequestDto.fromJson)
    );
  }

  Future<Response<void>> approveFriendRequest(int userId) async {
    var dto = FriendRequestRefDto(userId).toJson();
    return await put(
        "/friends/requests/approve",
        dto
    );
  }

  Future<Response<void>> rejectFriendRequest(int userId) async {
    var dto = FriendRequestRefDto(userId).toJson();
    return await put(
        "/friends/requests/reject",
        dto
    );
  }


}