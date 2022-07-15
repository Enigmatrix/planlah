import 'package:mobile/dto/place.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/dto/outing_step.dart';

class CreateOutingDto {
  String name;
  String description;
  int groupId;
  String start;
  String end;
  String voteDeadline;


  CreateOutingDto(
      this.name, this.description, this.groupId, this.start, this.end, this.voteDeadline);

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'groupId': groupId,
    "start": start,
    "end": end,
    "voteDeadline": voteDeadline,
  };
}

class OutingDto {
  int id;
  String name;
  String description;
  int groupId;
  String start;
  String end;
  List<List<OutingStepDto>> steps;
  String voteDeadline;


  OutingDto(this.id, this.name, this.description, this.groupId, this.start,
      this.end, this.steps, this.voteDeadline);

  OutingDto.fromJson(Map<String, dynamic> json)
      :  id = json['id'],
         name = json["name"],
         description = json['description'],
         groupId = json["groupId"],
         start = json["start"],
         end = json["end"],
        voteDeadline = json["voteDeadline"],
        steps = OutingStepDto.fromJsonToList(json["steps"]);
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
