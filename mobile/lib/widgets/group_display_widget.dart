import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/pages/chat_page.dart';

import '../model/chat_group.dart';


class GroupDisplay extends StatefulWidget {
  GroupSummaryDto chatGroup;
  // ChatGroup chatGroup;

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
                      // TODO: Figure out images
                      backgroundImage: NetworkImage("https://media1.popsugar-assets.com/files/thumbor/0ebv7kCHr0T-_O3RfQuBoYmUg1k/475x60:1974x1559/fit-in/500x500/filters:format_auto-!!-:strip_icc-!!-/2019/09/09/023/n/1922398/9f849ffa5d76e13d154137.01128738_/i/Taylor-Swift.jpg"),
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
                      "23.59",
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
