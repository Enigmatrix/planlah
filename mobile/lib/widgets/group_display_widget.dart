import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/pages/chat_page.dart';
import 'package:mobile/utils/time.dart';

import '../dto/user.dart';


class GroupDisplay extends StatefulWidget {
  GroupSummaryDto chatGroup;
  UserSummaryDto userSummaryDto;
  // ChatGroup chatGroup;

  GroupDisplay({
    Key? key,
    required this.chatGroup,
    required this.userSummaryDto,
  }) : super(key: key);

  @override
  State<GroupDisplay> createState() => _GroupDisplayState();
}

class _GroupDisplayState extends State<GroupDisplay> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => GroupChatPage(
          chatGroup: widget.chatGroup,
          userSummaryDto: widget.userSummaryDto,
        ));
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
                      // TODO: Figure out images
                      backgroundImage: NetworkImage(widget.chatGroup.imageLink),
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
                                widget.chatGroup.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.chatGroup.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.normal
                                  // TODO: widget.chatGroup.isMessageRead ? FontWeight.normal : FontWeight.bold
                                ),
                              )
                            ],
                          )
                        )
                    ),
                    Text(
                      (widget.chatGroup.lastSeenMessage == null)
                      ? ""
                      : TimeUtil.formatForGroup(context, widget.chatGroup.lastSeenMessage!.sentAt),
                      // TODO: widget.chatGroup.time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal
                        //TODO: widget.chatGroup.isMessageRead ? FontWeight.normal : FontWeight.bold
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
