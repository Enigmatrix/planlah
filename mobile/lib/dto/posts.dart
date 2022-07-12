import 'package:mobile/dto/outing.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/utils/time.dart';

class PostDto {
  int id;
  UserSummaryDto user;
  OutingStepDto outingStep;
  String text;
  String imageLink;
  DateTime postedAt;

  PostDto(this.id, this.user, this.outingStep, this.text, this.imageLink,
      this.postedAt);

  PostDto.fromJson(Map<String, dynamic> json):
    id = json["id"],
    user = UserSummaryDto.fromJson(json["user"]),
    outingStep = OutingStepDto.fromJson(json["outingStep"]),
    text = json["text"],
    imageLink = json["imageLink"],
    postedAt = TimeUtil.parseFromDto(json["postedAt"]);
}