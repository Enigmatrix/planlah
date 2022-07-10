import 'package:mobile/dto/user.dart';

class MessageDto {
  int id;
  DateTime sentAt;
  String content;
  UserSummaryDto user;

  MessageDto(this.id, this.sentAt, this.content, this.user);
}