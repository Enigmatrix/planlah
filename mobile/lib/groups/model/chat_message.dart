class ChatMessage {
  final String content;
  final String timestamp;
  final int byId;

  ChatMessage({
    required this.content,
    required this.timestamp,
    required this.byId,
  });

  static ChatMessage fromJson(json) => ChatMessage(
      content: json["content"],
      timestamp: json["timestamp"],
      byId: int.parse(json["byId"]));
}