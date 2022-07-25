import 'dart:typed_data';

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

  Future<Response<void>> editImage(Uint8List image) async {
    final formData = FormData({
      'image': MultipartFile(image, filename: 'avatar.png') // filename doesn't matter
    });
    return await put<void>(
        '/users/edit_image',
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

  Future<Response<CheckUserNameResultDto?>> checkUserName(String username) async {
    return await get(
        "/users/check_user_name",
        query: {
          "username": username,
        },
        decoder: decoderFor(CheckUserNameResultDto.fromJson)
    );
  }
}