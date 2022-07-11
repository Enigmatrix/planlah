import 'chat_message.dart';

class ChatGroup {
  final String groupId;
  final String groupName;
  final String mostRecentText;
  final String time;
  final String photoUrl;
  final String description;
  final bool isMessageRead;
  List<ChatMessage> messages;

  ChatGroup({
      required this.groupId,
      required this.groupName,
      required this.mostRecentText,
      required this.time,
      required this.photoUrl,
      required this.description,
      required this.isMessageRead,
      required this.messages,
  });

  static ChatGroup fromJson(json) => ChatGroup(
      groupId: json["groupId"],
      groupName: json["groupName"],
      mostRecentText: json["mostRecentText"],
      time: json["time"],
      photoUrl: json["photoUrl"],
      description: json["description"],
      isMessageRead: true,
      messages: getChatMessages()
  );

  // TODO: Temporary
  static List<ChatMessage> getChatMessages() {
    const data = [
      {
        "byId": "1",
        "content": "Hello, I am John!",
        "timestamp": "15 Aug 22:30"
        // "timestamp": "2022-05-30*13:23:55"
      },
      {
        "byId": "2",
        "content": "Hi John, how are you?",
        "timestamp": "15 Aug 22:31"
        // "timestamp": "2022-05-30*13:23:59"
      },
      {
        "byId": "1",
        "content": "I am learning Flutter right now!",
        // "timestamp": "2022-05-30*13:24:05"
        "timestamp": "15 Aug 22:32"
      },
      {
        "byId": "2",
        "content": "Wow! Flutter is so cool!",
        // "timestamp": "2022-05-30*13:24:14"
        "timestamp": "15 Aug 22:34"
      },
    ];

    return data.map<ChatMessage>(ChatMessage.fromJson).toList();
  }

  @override
  String toString() {
    return "i am not null";
  }
}