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
    'nickname': nickname,
    'firebaseToken': firebaseToken
  };
}
