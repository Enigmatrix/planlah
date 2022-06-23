import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/chat_page.dart';

import '../model/chat_group.dart';


class GroupDisplay extends StatefulWidget {
  ChatGroup chatGroup;

  GroupDisplay({
    Key? key,
    required this.chatGroup,
  }) : super(key: key);

  @override
  State<GroupDisplay> createState() => _GroupDisplayState();
}

class _GroupDisplayState extends State<GroupDisplay> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => ChatPage(chatGroup: widget.chatGroup));
      },
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: 10
        ),
        child: Row(
          children: <Widget>[
            Expanded(
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.chatGroup.photoUrl),
                      maxRadius: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.chatGroup.groupName,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.chatGroup.mostRecentText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: widget.chatGroup.isMessageRead ? FontWeight.normal : FontWeight.bold
                                ),
                              )
                            ],
                          )
                        )
                    ),
                    Text(
                      widget.chatGroup.time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: widget.chatGroup.isMessageRead ? FontWeight.normal : FontWeight.bold
                      ),
                    )
                  ]
                )
            )
          ],
        ),
      ),
    );
  }
}
