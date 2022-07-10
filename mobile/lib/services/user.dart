import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/services/base_connect.dart';

class UserService extends BaseConnect {
  Future<Response<UserSummaryDto?>> getInfo() async => await get<UserSummaryDto?>('/users/me/info', decoder: decoderFor<UserSummaryDto>((m) {
    return UserSummaryDto(
      m["id"] ?? "empty id",
      m["name"] ?? "empty name",
      m["username"] ?? "empty username",
      m["imageLink"] ?? "empty url",
    );
  }));

  Future<Response<void>> create(CreateUserDto dto) async {
    final formData = FormData(dto.toJson());
    return await post<void>('/users/create', formData);
  }
}