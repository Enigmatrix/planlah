import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile/dto/user.dart';

class MessageDto {
  String content;
  String sentAt;
  UserSummaryDto user;

  MessageDto(this.content, this.sentAt, this.user);

  MessageDto.fromJson(Map<String, dynamic> json):
    content = json["content"],
    sentAt = json["sentAt"],
    user = UserSummaryDto(json["user"]["username"], json["user"]["name"]);
}