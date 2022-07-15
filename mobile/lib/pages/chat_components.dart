import 'package:flutter/material.dart';
import 'package:mobile/dto/user.dart';

import '../dto/chat.dart';
import '../utils/time.dart';

typedef MessageFunction = void Function(String content);

class ChatComponents {

  static Widget buildMessageList(ScrollController scrollController, List<MessageDto> messages, UserSummaryDto user) {
    return Expanded(
        child: ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(10.0),
          itemBuilder: (context, index) => ChatComponents.buildMessage(messages[messages.length - 1 - index], user.id),
          itemCount: messages.length,
          controller: scrollController,
        )
    );
  }

  static Widget buildMessage(MessageDto message, int userId) {
    bool isUser = message.user.id == userId;
    return Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
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
                  TimeUtil.formatForFrontend(message.sentAt),
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

  static Widget buildInputWidget(MessageFunction fn) {
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
              child: TextField(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                ),
                controller: textEditingController,
                decoration: const InputDecoration.collapsed(
                    hintText: "Type here",
                    hintStyle: TextStyle(
                        color: Colors.black
                    )
                ),
              )
          ),

          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              color: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  fn(textEditingController.value.text);
                  textEditingController.clear();
                },
                color: Colors.blue,
              ),
            ),
          )
        ],
      ),
    );
  }
}