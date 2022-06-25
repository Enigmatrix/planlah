import 'package:get/get.dart';
import 'package:mobile/dto/chat.dart';
import 'package:mobile/services/auth.dart';
import 'package:mobile/services/base_connect.dart';
import 'package:mobile/utils/time.dart';

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
    print(TimeUtil.now());
    return await get(
        "/messages/all",
        query: {
          "groupId": groupId.toString(),
          "start": "2022-06-01T17:23:02.019Z",
          // TODO: Fix timezone locale bug (??????)
          "end": "2022-06-30T17:23:02.019Z"
          // "end": TimeUtil.now(),
        },
        decoder: decoderForList(MessageDto.fromJson)
    );
  }

  Future<Response<void>> sendMessage(SendMessageDto dto) async {
    return await post<void>(
        "/messages/send",
        dto.toJson()
    );
  }

}