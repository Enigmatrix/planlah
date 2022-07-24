import 'package:get/get.dart';
import 'package:mobile/dto/chat.dart';
import 'package:mobile/services/auth.dart';
import 'package:mobile/services/base_connect.dart';
import 'package:mobile/utils/time.dart';

import '../model/message.dart';

class MessageService extends BaseConnect {

  Future<Response<List<MessageDto>?>> getMessages(int groupId) async {
    print(TimeUtil.now());
    return await get(
        "/messages/all",
        query: {
          "groupId": groupId.toString(),
        },
        decoder: decoderForList(MessageDto.fromJson)
    );
  }

  Future<Response> sendMessage(SendMessageDto dto) async {
    return await post(
        "/messages/send",
        dto.toJson()
    );
  }

}