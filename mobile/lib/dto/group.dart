import 'dart:typed_data';

import 'package:get/get_connect/http/src/multipart/multipart_file.dart';

class GroupSummaryDto {
    int id;
    String name;
    String description;

    GroupSummaryDto(this.description, this.id, this.name);

    GroupSummaryDto.fromJson(Map<String, dynamic> json)
        : description = json['description'],
          id = json['id'],
          name = json["name"];

    Map<String, dynamic> toJson() => {
        'description': description,
        'id': id,
        'name': name
    };
}

class CreateGroupDto {
    String name;
    String description;
    Uint8List image;

    CreateGroupDto(
        this.name,
        this.description,
        this.image
        );

    Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "image": MultipartFile(image, filename: "groupAvatar.png")
    };
}