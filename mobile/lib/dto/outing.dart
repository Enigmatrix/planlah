import 'package:mobile/dto/user.dart';

class OutingTimingDto {
  String start;
  String end;

  OutingTimingDto(this.start, this.end);
}

class OutingStepVoteDto {
  bool vote;
  UserSummaryDto userSummaryDto;

  OutingStepVoteDto(this.vote, this.userSummaryDto);

  OutingStepVoteDto.fromJson(Map<String, dynamic> json):
      vote = json["vote"],
      userSummaryDto = json["user"];
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
      outingStepVoteDtos = json["votes"],
      voteDeadline = json["voteDeadline"];
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
         outingStepDto = json["steps"],
         outingTimingDto = json["timing"];
}
