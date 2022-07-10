import 'package:mobile/dto/place.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/dto/outing_step.dart';

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

class OutingDto {
  int id;
  String name;
  String description;
  int groupId;
  String start;
  String end;
  List<List<OutingStepDto>> steps;


  OutingDto(this.id, this.name, this.description, this.groupId, this.start,
      this.end, this.steps);

  OutingDto.fromJson(Map<String, dynamic> json)
      :  id = json['id'],
         name = json["name"],
         description = json['description'],
         groupId = json["groupId"],
         start = json["start"],
         end = json["end"],
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
