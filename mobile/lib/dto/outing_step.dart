import 'package:mobile/dto/place.dart';
import 'package:mobile/dto/user.dart';

class CreateOutingStepDto {
  String description;
  int outingId;
  int placeId;
  String start;
  String end;


  CreateOutingStepDto(
      this.outingId,
      this.description,
      this.placeId,
      this.start,
      this.end);

  Map<String, dynamic> toJson() => {
    "description": description,
    "outingId": outingId,
    "placeId": placeId,
    "start": start,
    "end": end,
  };
}

class OutingStepVoteDto {
  bool vote;
  UserSummaryDto userSummaryDto;

  OutingStepVoteDto(this.vote, this.userSummaryDto);

  OutingStepVoteDto.fromJson(Map<String, dynamic> json):
        vote = json["vote"],
        userSummaryDto = UserSummaryDto.fromJson(json["user"]);

  static List<OutingStepVoteDto> fromJsonToList(List<dynamic> json) {
    List<OutingStepVoteDto> result = [];
    for (int i = 0; i < json.length; i++) {
      result.add(OutingStepVoteDto.fromJson(json[i]));
    }
    return result;
  }
}

class OutingStepDto {
  int id;
  int outingId;
  PlaceDto place;
  String description;
  String start;
  String end;
  List<OutingStepVoteDto> outingStepVoteDtos;

  OutingStepDto(
      this.id,
      this.outingId,
      this.place,
      this.description,
      this.start,
      this.end,
      this.outingStepVoteDtos);

  OutingStepDto.fromJson(Map<String, dynamic> json):
        id = json["id"],
        outingId = json["outingId"],
        place = PlaceDto.fromJson(json["place"]),
        description = json["description"],
        start = json["start"],
        end = json["end"],
        outingStepVoteDtos = OutingStepVoteDto.fromJsonToList(json["votes"]);

  static List<List<OutingStepDto>> fromJsonToList(List<dynamic> json) {
    List<List<OutingStepDto>> result = [];
    for(int i = 0; i < json.length; i++) {
      List<OutingStepDto> tmp = [];
      for(int j = 0; j < json[i].length; j++) {
        tmp.add(OutingStepDto.fromJson(json[i][j]));
      }
      result.add(tmp);
    }
    return result;
  }
}
