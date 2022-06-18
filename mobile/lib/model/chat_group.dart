
// TODO: Add
class ChatGroup {
  final String groupId;
  final String groupName;
  final String mostRecentText;
  final String time;
  final String photoUrl;
  final String description;

  const ChatGroup({
      required this.groupId,
      required this.groupName,
      required this.mostRecentText,
      required this.time,
      required this.photoUrl,
      required this.description,
  });

  static ChatGroup fromJson(json) => ChatGroup(
      groupId: json["groupId"],
      groupName: json["groupName"],
      mostRecentText: json["mostRecentText"],
      time: json["time"],
      photoUrl: json["photoUrl"],
      description: json["description"]);
}