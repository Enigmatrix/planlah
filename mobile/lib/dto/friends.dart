import 'package:mobile/dto/user.dart';

class FriendRequestDto {
  UserSummaryDto from;

  FriendRequestDto(this.from);

  FriendRequestDto.fromJson(Map<String, dynamic> json):
      from = UserSummaryDto.fromJson(json["from"]);
}