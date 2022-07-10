import 'dart:typed_data';
import 'package:get/get.dart';

import 'chat.dart';


import 'package:get/get_connect/http/src/multipart/multipart_file.dart';

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

/// Cool way to make an enum that supports string values in Dart
abstract class ExpiryOption {
    static String get oneHour => "oneHour";
    static String get oneDay => "oneDay";
    static String get never => "never";
}

class CreateGroupInviteDto {
    String expiryOption;
    int groupId;

    CreateGroupInviteDto(this.expiryOption, this.groupId);

    Map<String, dynamic> toJson() => {
        "expiryOption": expiryOption,
        "groupId": groupId
    };
}

class GroupInviteDto {
    String expiry;
    int groupId;
    String id;
    String url;

    GroupInviteDto(this.expiry, this.groupId, this.id, this.url);

    GroupInviteDto.fromJson(Map<String, dynamic> json)
        :   expiry = json["expiry"] ?? "never",  // if expiryOption == null, this will be null
            groupId = json["groupId"],
            id = json["id"],
            url = json["url"];
}