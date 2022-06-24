import 'package:mobile/dto/user.dart';

class CreateOutingDto {
  String name;
  String description;
  int groupId;

  CreateOutingDto(this.name, this.description, this.groupId);

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'groupId': groupId
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

  static List<OutingStepVoteDto> fromJsonToList(List<Map<String, dynamic>> json) {
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
  String when;
  List<OutingStepVoteDto> outingStepVoteDtos;
  String voteDeadline;

  OutingStepDto(this.id, this.name, this.description, this.whereName,
      this.wherePoint, this.when, this.outingStepVoteDtos, this.voteDeadline);

  OutingStepDto.fromJson(Map<String, dynamic> json):
      id = json["id"],
      name = json["name"],
      description = json["description"],
      whereName = json["whereName"],
      wherePoint = json["wherePoint"],
      when = json["when"],
      outingStepVoteDtos = OutingStepVoteDto.fromJsonToList(json["votes"]),
      voteDeadline = json["voteDeadline"];

  static List<OutingStepDto> fromJsonToList(List<Map<String, dynamic>> json) {
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
  List<OutingStepDto> outingStepDto;
  OutingTimingDto outingTimingDto;


  OutingDto(this.id, this.name, this.description, this.groupId,
      this.outingStepDto, this.outingTimingDto);

  OutingDto.fromJson(Map<String, dynamic> json)
      :  id = json['id'],
         name = json["name"],
         description = json['description'],
         groupId = json["groupId"],
         outingStepDto = OutingStepDto.fromJsonToList(json["steps"]),
         outingTimingDto = OutingTimingDto.fromJson(json["timing"]);
}
