import 'package:mobile/dto/user.dart';

class FriendRequestDto {
  UserSummaryDto from;

  FriendRequestDto(this.from);

  FriendRequestDto.fromJson(Map<String, dynamic> json):
      from = UserSummaryDto.fromJson(json["from"]);
}

class FriendRequestRefDto {
  int userId;

  FriendRequestRefDto(this.userId);

  Map<String, dynamic> toJson() => {
    "userId": userId
  };
}

class CreateFriendRequestDto {
  int userId;

  CreateFriendRequestDto(this.userId);

  Map<String, dynamic> toJson() => {
    "id": userId
  };
}
