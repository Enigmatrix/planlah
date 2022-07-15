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
