import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:mobile/groups/model/chat_group.dart';
import 'package:mobile/main.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(group.groupName),
      centerTitle: true,
    ),
    body: Stack(
      children: <Widget>[
        Column(
          children: [
            buildChat(messages),
            buildInputWidget(),
          ],
        )
      ],
    )
  );

  Widget buildChat(List<ChatMessage> messages) {
    final ScrollController scrollController = ScrollController();
    return Flexible(
        child: ListView.builder(
          padding: const EdgeInsets.all(10.0),
          itemBuilder: (context, index) => buildMessage(messages[index]),
          itemCount: messages.length,
          controller: scrollController,
        )
    );
  }


  Widget buildMessage(ChatMessage message) {
    // Hard code for now
    bool isUser = message.byId == 1;
    return Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                width: 200.0,
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.grey
                      : Colors.greenAccent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: const EdgeInsets.only(right: 10.0),
                child: Text(
                  message.content,
                  style: isUser
                      ? const TextStyle(color: Colors.white)
                      : const TextStyle(color: Colors.black),
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(left: 5.0, top: 5.0, bottom: 5.0),
                child: Text(
                  message.timestamp,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12.0,
                    fontStyle: FontStyle.normal
                  ),
                ),
              )
            ],
          )
        ]
      );
  }

  Widget buildInputWidget() {
    final TextEditingController textEditingController = TextEditingController();
    return Container(
      width: double.infinity,
      height: 50.0,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white,
            width: 0.5,
          ),
        ),
        color: Colors.white
      ),
      child: Row(
        children: <Widget>[
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.face),
                color: Colors.grey,
              ),
            ),
          ),

          Flexible(
              child: Container(
                child: TextField(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                  ),
                  controller: textEditingController,
                  decoration: const InputDecoration.collapsed(
                    hintText: "Type here",
                    hintStyle: TextStyle(
                        color: Colors.grey
                    )
                  ),
                )
              )
          ),

          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              color: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {},
                color: Colors.blue,
              ),
            ),
          )
        ],
      ),
    );
  }


}