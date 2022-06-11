import 'package:get/get.dart';
import 'package:mobile/model/user.dart';
import 'package:mobile/services/auth.dart';
import 'package:mobile/services/base_connect.dart';

class UserService extends BaseConnect {
  Future<Response<UserInfo>> getInfo() async => await get<UserInfo>('/users/me/info');
}