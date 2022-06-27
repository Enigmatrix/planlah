import 'package:get/get.dart';
import 'package:mobile/model/user.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/services/base_connect.dart';

class UserService extends BaseConnect {
  Future<Response<UserInfo?>> getInfo() async => await get<UserInfo?>('/users/me/info', decoder: decoderFor<UserInfo>((m) {
    return UserInfo(
      name: m["name"] ?? "empty name",
      username: m["username"] ?? "empty username",
      imageUrl: m["imageLink"] ?? "empty url",
    );
  }));

  Future<Response<void>> create(CreateUserDto dto) async {
    final formData = FormData(dto.toJson());
    return await post<void>('/users/create', formData);
  }
}