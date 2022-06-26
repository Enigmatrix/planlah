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

class OutingTimingDto {
  String start;
  String end;

  OutingTimingDto(this.start, this.end);

  OutingTimingDto.fromJson(Map<String, dynamic> json):
      start = json["start"],
      end = json["end"];
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
  String name;
  String description;
  String whereName;
  String wherePoint;
  String start;
  String end;
  List<OutingStepVoteDto> outingStepVoteDtos;
  String voteDeadline;


  OutingStepDto(
      this.id,
      this.name,
      this.description,
      this.whereName,
      this.wherePoint,
      this.start,
      this.end,
      this.outingStepVoteDtos,
      this.voteDeadline);

  OutingStepDto.fromJson(Map<String, dynamic> json):
      id = json["id"],
      name = json["name"],
      description = json["description"],
      whereName = json["whereName"],
      wherePoint = json["wherePoint"],
      start = json["start"],
      end = json["end"],
      outingStepVoteDtos = OutingStepVoteDto.fromJsonToList(json["votes"]),
      voteDeadline = json["voteDeadline"];

  static List<OutingStepDto> fromJsonToList(List<dynamic> json) {
    List<OutingStepDto> result = [];
    for(int i = 0; i < json.length; i++) {
      result.add(OutingStepDto.fromJson(json[i]));
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
  List<OutingStepDto> outingStepDto;


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

  OutingStepDto getOutingStep(int index) {
    return outingStepDto[index];
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
