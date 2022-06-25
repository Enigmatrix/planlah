import 'dart:typed_data';
import 'package:get/get.dart';

import 'chat.dart';


class GroupSummaryDto {
    int id;
    String name;
    String imageLink;
    String description;
    MessageDto? lastSeenMessage;
    int? unreadMessageCount;


    GroupSummaryDto(this.id, this.name, this.imageLink, this.description,
      this.lastSeenMessage, this.unreadMessageCount);

    GroupSummaryDto.fromJson(Map<String, dynamic> json)
        : id = json['id'],
          name = json["name"],
          imageLink = json["imageLink"],
          description = json['description'],
          lastSeenMessage = json["lastSeenMessage"] == null ? null : MessageDto.fromJson(json["lastSeenMessage"]),
          unreadMessageCount = json["unreadMessagesCount"];


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