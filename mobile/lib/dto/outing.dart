import 'package:mobile/dto/place.dart';
import 'package:mobile/dto/user.dart';

class CreateOutingDto {
  String name;
  String description;
  int groupId;
  String start;
  String end;


  CreateOutingDto(
      this.name, this.description, this.groupId, this.start, this.end);

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'groupId': groupId,
    "start": start,
    "end": end
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
  Place place;
  String description;
  String start;
  String end;
  List<OutingStepVoteDto> outingStepVoteDtos;
  String voteDeadline;


  OutingStepDto(
      this.id,
      this.place,
      this.description,
      this.start,
      this.end,
      this.outingStepVoteDtos,
      this.voteDeadline);

  OutingStepDto.fromJson(Map<String, dynamic> json):
      id = json["id"],
      place = Place.fromJson(json["place"]),
      description = json["description"],
      start = json["start"],
      end = json["end"],
      outingStepVoteDtos = OutingStepVoteDto.fromJsonToList(json["votes"]),
      voteDeadline = json["voteDeadline"];

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

class OutingDto {
  int id;
  String name;
  String description;
  int groupId;
  String start;
  String end;
  List<List<OutingStepDto>> outingStepDto;


  OutingDto(this.id, this.name, this.description, this.groupId, this.start,
      this.end, this.outingStepDto);

  OutingDto.fromJson(Map<String, dynamic> json)
      :  id = json['id'],
         name = json["name"],
         description = json['description'],
         groupId = json["groupId"],
         start = json["start"],
         end = json["end"],
         outingStepDto = OutingStepDto.fromJsonToList(json["steps"]);

  int getSize() {
    return outingStepDto.length;
  }

  int getCurrentOuting() {
    return getSize() - 1;
  }
}

class GetActiveOutingDto {
  int groupId;

  GetActiveOutingDto(this.groupId);

  Map<String, dynamic> toJson() {
    return {
      "groupId": groupId.toString()
    };
  }
}
