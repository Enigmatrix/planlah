/// Data model for Chat User in the Chat Groups page.

class ChatUser {
  final String id;
  final String photoUrl;
  final String displayName;
  final String phoneNumber;
  final String aboutMe;

  const ChatUser({
    required this.id,
    required this.photoUrl,
    required this.displayName,
    required this.phoneNumber,
    required this.aboutMe});

  static ChatUser fromJson(json) => ChatUser(
      id: json["id"],
      photoUrl: json["photoUrl"],
      displayName: json["displayName"],
      phoneNumber: json["phoneNumber"],
      aboutMe: json["aboutMe"]);

}