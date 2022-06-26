class UserInfo {
  final String name;
  final String username;
  final String imageUrl;



  UserInfo({
    required this.name,
    required this.username,
    required this.imageUrl
  });

  UserInfo.fromJson(Map<String, dynamic> json):
    name = json["name"],
    username = json["username"],
    imageUrl = json["imageUrl"];

}