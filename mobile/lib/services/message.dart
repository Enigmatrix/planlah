import 'package:get/get.dart';
import 'package:mobile/services/auth.dart';

import '../model/message.dart';

class MessageService extends GetConnect {
  @override
  void onInit() {
    final auth = Get.find<AuthService>();

    httpClient.baseUrl = "http:localhost:8080";

    httpClient.addAuthenticator<dynamic>((request) async {
      final token = await auth.user.value?.getIdToken();
      if (token == null) return request;

      final response = await post('/auth/verify', { "token": token });
      Get.log("POST Verification of Data");
      request.headers["Authorization"] = response.body["token"];
      return request;
    });

    // retry token verification 3 times
    httpClient.maxAuthRetries = 3;
  }

  // TODO: Actually find out what the API call is supposed to be
  Future<Response<MessageInfo>> getInfo() => get<MessageInfo>("/messages/me");


}