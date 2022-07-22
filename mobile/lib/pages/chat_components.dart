import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/pages/profile_page.dart';

import '../dto/chat.dart';
import '../utils/time.dart';

typedef MessageFunction = void Function(String content);

class ChatComponents {

  /// I can't do this...
  static const Color USER_MESSAGE_BACKGROUND = Colors.blue;
  static const Color USER_NAME = Colors.black;
  static const Color OTHER_MESSAGE_BACKGROUND = Colors.grey;
  static const Color OTHER_NAME = Colors.black;
  static const Color TEXT_COLOR = Colors.white;
  static const Color TIMESTAMP_COLOR = Colors.white70;

  static const double verticalPadding = 6.0;

  static Widget buildMessageList(
      ScrollController scrollController,
      List<MessageDto> messages,
      UserProfileDto user,
      bool isDm
      ) {
    return Expanded(
        child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(height: verticalPadding),
          reverse: true,
          padding: const EdgeInsets.all(16.0),
          itemBuilder: (context, index) => ChatComponents.buildMessage(messages[messages.length - 1 - index], user.id, isDm),
          itemCount: messages.length,
          controller: scrollController,
        )
    );
  }

  /// Encapsulates UI logic depending on whether its a DM or a group chat message
  static Widget buildMessage(MessageDto message, int userId, bool isDm) {
    bool isUser = message.user.id == userId;
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        (!isUser)
          ? buildUserAvatar(message.user)
          : const SizedBox.shrink(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            buildMessageBodyComponent(message, isUser, isDm),
            // buildMessageTimestampComponent(message),
          ],
        ),
        (isUser)
          ? buildUserAvatar(message.user)
          : const SizedBox.shrink()
      ],
    );
  }

  static Widget buildUserAvatar(UserSummaryDto user) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProfilePage(userId: user.id));
      },
      child: CircleAvatar(
        backgroundImage: NetworkImage(user.imageLink),
      ),
    );
  }

  static Widget buildMessageBodyComponent(MessageDto message, bool isUser, bool isDm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15.0, 10.0, 0.0, 0.0),
      width: 200.0,
      decoration: BoxDecoration(
        color: isUser
            ? USER_MESSAGE_BACKGROUND
            : OTHER_MESSAGE_BACKGROUND,
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.only(right: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (isDm)
            ? const SizedBox.shrink()
            : buildMessageUserComponent(message.user, isUser),
          SelectableText(
            message.content,
            style: const TextStyle(
              color: TEXT_COLOR
            ),
          ),
          const SizedBox(height: 4),
          buildMessageTimestampComponent(message)
        ],
      ),
    );
  }

  static Widget buildMessageUserComponent(UserSummaryDto user, bool isUser) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProfilePage(userId: user.id));
      },
      child: Text(
        user.username,
        style: TextStyle(
          color: (isUser) ? USER_NAME : OTHER_NAME
        ),
      ),
    );
  }

  static Widget buildMessageTimestampComponent(MessageDto message) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Text(
        TimeUtil.formatForFrontend(message.sentAt),
        style: const TextStyle(
            color: TIMESTAMP_COLOR,
            fontSize: 12.0,
            fontStyle: FontStyle.normal
        ),
      ),
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