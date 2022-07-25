import 'dart:typed_data';
import 'package:get/get.dart';

class CreateUserDto {
  String name;
  String nickname;
  String gender;
  String town;
  String firebaseToken;
  List<String?> attractions;
  List<String?> food;
  Uint8List image;

  CreateUserDto(
      this.name,
      this.nickname,
      this.gender,
      this.town,
      this.firebaseToken,
      this.attractions,
      this.food,
      this.image,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'username': nickname,
    'gender': gender,
    'town': town,
    'firebaseToken': firebaseToken,
    'attractions': attractions.map((e) => e!).toList(),
    'food': food.map((e) => e!).toList(),
    'image': MultipartFile(image, filename: 'avatar.png') // filename doesn't matter
  };
}

class CheckUserNameResultDto {
  bool isUnique;

  CheckUserNameResultDto(this.isUnique);

  CheckUserNameResultDto.fromJson(Map<String, dynamic> json):
        isUnique = json["isUnique"];
}

class UserSummaryDto {
  int id;
  String username;
  String name;
  String imageLink;

  UserSummaryDto(this.id, this.username, this.name, this.imageLink);

  UserSummaryDto.fromJson(Map<String, dynamic> json):
      id = json["id"],
      username = json["username"],
      name = json["name"],
      imageLink = json["imageLink"];
}

class UserProfileDto {
  int id;
  String username;
  String name;
  String imageLink;
  int postCount;
  int reviewCount;
  int friendCount;

  UserProfileDto(this.id, this.username, this.name, this.imageLink, this.postCount, this.reviewCount, this.friendCount);

  UserProfileDto.fromJson(Map<String, dynamic> json):
        id = json["id"],
        username = json["username"],
        name = json["name"],
        postCount = json["postCount"],
        reviewCount = json["reviewCount"],
        friendCount = json["friendCount"],
        imageLink = json["imageLink"];
}

class SearchUsersDto {
  int page;
  String query;

  SearchUsersDto(this.page, this.query);

  Map<String, dynamic> toJson() => {
    "page": page.toString(),
    "query": query
  };
}

class UserRefDto {
  int id;

  UserRefDto(this.id);

  Map<String, dynamic> toJson() => {
    "id": id.toString()
  };
}