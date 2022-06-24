class CreateUserDto {
  String name;
  String nickname;
  String gender;
  String town;
  String firebaseToken;
  List<String?> attractions;
  List<String?> food;

  CreateUserDto(
      this.name,
      this.nickname,
      this.gender,
      this.town,
      this.firebaseToken,
      this.attractions,
      this.food,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'username': nickname,
    'gender': gender,
    'town': town,
    'firebaseToken': firebaseToken,
    'attractions': attractions.map((e) => e!).toList(),
    'food': food.map((e) => e!).toList(),
  };
}

class UserSummaryDto {
  String username;
  String name;

  UserSummaryDto(this.username, this.name);

  UserSummaryDto.fromJson(Map<String, dynamic> json):
      username = json["nickname"],
      name = json["name"];
}
