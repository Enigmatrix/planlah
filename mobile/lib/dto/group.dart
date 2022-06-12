class GroupSummaryDto {
    String description;
    int id;
    String name;

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