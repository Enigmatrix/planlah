import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/services/base_connect.dart';

class UserService extends BaseConnect {
  Future<Response<UserProfileDto?>> getInfo() async => await get<UserProfileDto?>(
      '/users/me/info',
      decoder: decoderFor(UserProfileDto.fromJson)
  );

  Future<Response<UserProfileDto?>> getFriendInfo(int friendId) async => await get<UserProfileDto?>(
      '/users/friend/info',
      query: {
        "id": friendId.toString()
      },
      decoder: decoderFor(UserProfileDto.fromJson)
  );

  Future<Response<UserSummaryDto?>> getUserInfo(int id) async {
    UserRefDto dto = UserRefDto(id);
    return await get<UserSummaryDto?>(
      "/users/get",
      query: dto.toJson(),
      decoder: decoderFor(UserSummaryDto.fromJson)
    );
  }

  Future<Response<void>> create(CreateUserDto dto) async {
    final formData = FormData(dto.toJson());
    return await post<void>(
        '/users/create',
        formData
    );
  }

  Future<Response<List<UserSummaryDto>?>> searchForFriends(int page, String query) async {
    SearchUsersDto dto = SearchUsersDto(page, query);
    return await get(
      "/users/search_for_friends",
      query: dto.toJson(),
      decoder: decoderForList(UserSummaryDto.fromJson)
    );
  }
}