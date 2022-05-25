import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mobile/groups/model/chat_group.dart';
import 'package:mobile/main.dart';

import '../model/chat_message.dart';

class ChatPage extends StatefulWidget {


  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  // Replace with actual retrieving from database in the future
  List<ChatMessage> messages = getChatMessages();
  // Retrieve arguments from Get navigation
  ChatGroup group = Get.arguments;
  // Hard code for now
  static List<ChatMessage> getChatMessages() {
    const data = [
      {
        "idFrom": "John",
        "content": "Hello, I am John!",
        "timestamp": "2022-05-30*13:23:55"
      },
      {
        "idFrom": "Joal",
        "content": "Hi John, how are you?",
        "timestamp": "2022-05-30*13:23:59"
      },
      {
        "idFrom": "John",
        "content": "I am learning Flutter right now!",
        "timestamp": "2022-05-30*13:24:05"
      },
      {
        "idFrom": "Joal",
        "content": "Wow! Flutter is so cool!",
        "timestamp": "2022-05-30*13:24:14"
      },
    ];

    return data.map<ChatMessage>(ChatMessage.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(group.groupName),
      centerTitle: true,
    ),
    body: Center(
      child: buildChat(messages),
    )
  );

  Widget buildChat(List<ChatMessage> messages) => ListView.builder(
    itemCount: messages.length,
    itemBuilder: (context, index) {
      final message = messages[index];
      // Hard code for now
      bool isUser = message.idFrom == "John";
      return Container(
        padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
        child: Align(
          // Hard code the alignment for now
          alignment: (isUser ? Alignment.topLeft : Alignment.topRight),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: (isUser ? Colors.blue : Colors.purpleAccent)
            ),
            padding: EdgeInsets.all(16),
            child: Text(message.content)),
          )
      );
    }
  );


}
