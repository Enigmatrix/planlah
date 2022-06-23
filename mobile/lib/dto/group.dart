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