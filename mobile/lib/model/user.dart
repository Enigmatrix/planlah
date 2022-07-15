class UserInfo {
  final String name;
  final String username;
  final String imageUrl;
  final int id;



  UserInfo({
    required this.id,
    required this.name,
    required this.username,
    required this.imageUrl
  });

  UserInfo.fromJson(Map<String, dynamic> json):
    id = json["id"],
    name = json["name"],
    username = json["username"],
    imageUrl = json["imageLink"];

}