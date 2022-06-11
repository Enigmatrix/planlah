class CreateUserDto {
  String name;
  String nickname;
  String firebaseToken;

  CreateUserDto(this.name, this.nickname, this.firebaseToken);

  Map<String, dynamic> toJson() => {
    'name': name,
    'nickname': nickname,
    'firebaseToken': firebaseToken
  };
}
