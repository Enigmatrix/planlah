

class ChatGroup {
  final String groupId;
  final String groupName;
  final String photoUrl;
  final String description;

  const ChatGroup({
      required this.groupId,
      required this.groupName,
      required this.photoUrl,
      required this.description,
  });

  static ChatGroup fromJson(json) => ChatGroup(
      groupId: json["groupId"],
      groupName: json["groupName"],
      photoUrl: json["photoUrl"],
      description: json["description"]);

}