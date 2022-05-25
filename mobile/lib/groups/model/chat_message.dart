class ChatMessage {
  final String idFrom;
  final String timestamp;
  final String content;

  ChatMessage({
    required this.idFrom,
    required this.timestamp,
    required this.content,
  });

  static ChatMessage fromJson(json) => ChatMessage(
      idFrom: json["idFrom"],
      timestamp: json["timestamp"],
      content: json["content"]);

}