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
