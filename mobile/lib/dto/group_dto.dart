class GroupSummaryDTO {
    String description;
    int id;
    String name;

    GroupSummaryDTO(this.description, this.id, this.name);

    GroupSummaryDTO.fromJson(Map<String, dynamic> json)
        : description = json['description'],
          id = json['id'],
          name = json["name"];

    Map<String, dynamic> toJson() => {
        'description': description,
        'id': id,
        'name': name
    };
}