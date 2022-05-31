import 'package:get/get.dart';
import 'package:mobile/model/user.dart';
import 'package:mobile/services/auth.dart';

class BaseConnect extends GetConnect {
  late AuthService auth;

  @override
  void onInit() {
    auth = Get.find<AuthService>();

    // TODO make this configurable
    httpClient.baseUrl = "http://localhost:8080";

    httpClient.addAuthenticator<dynamic>((request) async {
      final token = await auth.user.value?.getIdToken();
      if (token == null) return request;

      final response = await post('/auth/verify', { "token": token });
      Get.log('POST Verification of Data');
      request.headers['Authorization'] = response.body['token'];
      return request;
    });

    // retry token verification 3 times
    httpClient.maxAuthRetries = 3;
  }

}