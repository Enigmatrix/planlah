import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:mobile/dto/chat.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/model/chat_group.dart';
import 'package:mobile/main.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/pages/outing_page.dart';
import 'package:mobile/pages/view_all_outings.dart';
import 'package:mobile/services/message.dart';
import 'package:mobile/services/outing.dart';

import '../model/chat_message.dart';
import '../model/outing_list.dart';
import '../model/outing_steps.dart';
import 'CreateOutingPage.dart';

class GroupChatPage extends StatefulWidget {
  GroupSummaryDto chatGroup;

  GroupChatPage({
    Key? key,
    required this.chatGroup,
  }) : super(key: key);

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {

  final messageService = Get.find<MessageService>();
  final outingService = Get.find<OutingService>();

  late var messages = <MessageDto>[];
  late var outings = <OutingDto>[];

  @override
  void initState() {
    super.initState();
    messageService.getMessages(widget.chatGroup.id)
      .then((value) {
      setState(() {
        messages = value.body!;
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: <Widget>[
        Container(
          padding: const EdgeInsets.only(right: 32),
          child: InkWell(
            onTap: () {
              // TODO: Group description
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    widget.chatGroup.imageLink,
                  ),
                  maxRadius: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.chatGroup.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
            onPressed: () {
              // TODO: Itinerary
              Get.to(() => CreateOutingPage(groupId: widget.chatGroup.id));
              // if (widget.chatGroup.getGroupInfo().isInOuting()) {
              //   // Display currently itinerary
              //   Get.to(() => OutingPage(outing: Outing.getOuting()));
              // } else {
              //   Get.to(() => CreateOutingPage());
              // }
            },
            icon: const Icon(
                Icons.assignment
            ),
        ),
        PopupMenuButton(
            icon: const Icon(
              Icons.more_vert,
            ),
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem>[
                PopupMenuItem(
                  onTap: () {
                    // TODO: Display group description, same thing as above
                  },
                  child: const Text("About")
                ),
                PopupMenuItem(
                  onTap: () {
                    // TODO: Add past outings page
                    viewPastOutings();
                  },
                  child: const Text("See past outings")
                ),
                PopupMenuItem(
                    onTap: () {
                      // TODO: Add people
                    },
                    child: const Text("Jio")
                ),
                PopupMenuItem(
                    onTap: () {
                      // TODO: Kick people
                    },
                    child: const Text("Kick")
                ),
                PopupMenuItem(
                    onTap: () {
                      // TODO: Leave group
                    },
                    child: const Text("Leave")
                ),
              ];
            }
        ),
      ],
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

  void viewPastOutings() {
    print(widget.chatGroup.id);
    outingService
      .getAllOutings(widget.chatGroup.id)
      .then((value) {
          setState(() {
            if (value.body == null || value.body!.isEmpty) {
              Get.snackbar(
                "Operation not possible: ",
                "Your group has not had any outings yet :(",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.black
              );
            } else {
              outings = value.body!;
              Get.to(() => ViewAllOutingsPage(pastOutings: outings));
            }
          });
      });
  }


  Widget buildChat(List<MessageDto> messages) {
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


  Widget buildMessage(MessageDto message) {
    // Hard code for now
    bool isUser = Random().nextDouble() <= 0.5;
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
                  message.sentAt,
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
