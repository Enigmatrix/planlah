import 'package:get/get.dart';
import 'package:mobile/dto/chat.dart';
import 'package:mobile/services/auth.dart';
import 'package:mobile/services/base_connect.dart';

import '../model/message.dart';

class MessageService extends BaseConnect {
  // @override
  // void onInit() {
  //   final auth = Get.find<AuthService>();
  //
  //   httpClient.baseUrl = "http:localhost:8080";
  //
  //   httpClient.addAuthenticator<dynamic>((request) async {
  //     final token = await auth.user.value?.getIdToken();
  //     if (token == null) return request;
  //
  //     final response = await post('/auth/verify', { "token": token });
  //     Get.log("POST Verification of Data");
  //     request.headers["Authorization"] = response.body["token"];
  //     return request;
  //   });
  //
  //   // retry token verification 3 times
  //   httpClient.maxAuthRetries = 3;
  // }

  // TODO: Actually find out what the API call is supposed to be
  Future<Response<MessageInfo>> getInfo() => get<MessageInfo>("/messages/me");

  Future<Response<List<MessageDto>?>> getMessages(int groupId) async {
    final now = DateTime.now();
    final selectedTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    print(selectedTime.toString());
    return await get(
        "/messages/all",
        query: {
          "groupId": groupId.toString(),
          "start": "2022-06-01T17:23:02.019Z",
          "end": "2022-06-23T17:23:02.019Z",
          // "end": selectedTime.toString(),
        },
        decoder: decoderForList(MessageDto.fromJson)
    );
  }

  Future<Response<void>> sendMessage(String message, int groupId) async {
    return await post<void>(
        "/messages/send",
        {
          "content": message,
          "groupId": groupId.toString(),
        }
    );
  }

}