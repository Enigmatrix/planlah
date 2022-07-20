import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/pages/group_chat_page.dart';
import 'package:mobile/utils/time.dart';

import '../dto/user.dart';


class GroupDisplay extends StatefulWidget {
  GroupSummaryDto chatGroup;
  UserProfileDto userProfile;
  // ChatGroup chatGroup;

  GroupDisplay({
    Key? key,
    required this.chatGroup,
    required this.userProfile,
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
          userProfile: widget.userProfile,
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
                    buildGroupIcon(),
                    const SizedBox(width: 16),
                    buildGroupChatHeader(),
                  ]
                )
            )
          ],
        ),
      ),
    );
  }

  Widget buildGroupIcon() {
    return CircleAvatar(
      backgroundImage: NetworkImage(widget.chatGroup.imageLink),
      maxRadius: 30,
    );
  }

  Widget buildGroupChatHeader() {
    return Expanded(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      widget.chatGroup.description,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.normal
                      ),
                    ),
                    buildTimeAgoLabel()
                  ],
                )
              ],
            )
        )
    );
  }

  Widget buildTimeAgoLabel() {
    return Text(
      (widget.chatGroup.lastSeenMessage == null)
          ? ""
          : TimeUtil.formatForGroup(context, widget.chatGroup.lastSeenMessage!.sentAt),
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal
      ),
    );
  }
}
