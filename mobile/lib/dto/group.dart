class GroupSummaryDto {
    int id;
    String name;
    String description;

    GroupSummaryDto(this.description, this.id, this.name);

    GroupSummaryDto.fromJson(Map<String, dynamic> json)
        : description = json['description'],
          id = json['id'],
          name = json["name"];

    Map<String, dynamic> toJson() => {
        'description': description,
        'id': id,
        'name': name
    };
}

class CreateGroupDto {
    String name;
    String description;

    CreateGroupDto(this.name, this.description);

    Map<String, dynamic> toJson() => {
        "name": name,
        "description": description
    };
}