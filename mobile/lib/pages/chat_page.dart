import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mobile/dto/chat.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/pages/outing_page.dart';
import 'package:mobile/pages/view_all_outings.dart';
import 'package:mobile/services/group.dart';
import 'package:mobile/services/message.dart';
import 'package:mobile/services/outing.dart';
import 'package:group_button/group_button.dart';

import '../dto/user.dart';
import '../utils/time.dart';
import 'CreateOutingPage.dart';

class GroupChatPage extends StatefulWidget {
  GroupSummaryDto chatGroup;
  UserSummaryDto userSummaryDto;

  GroupChatPage({
    Key? key,
    required this.chatGroup,
    required this.userSummaryDto,
  }) : super(key: key);

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {

  // Services
  final messageService = Get.find<MessageService>();
  final outingService = Get.find<OutingService>();
  final groupService = Get.find<GroupService>();

  // Messages sent in the group
  late var messages = <MessageDto>[];
  // Check if group is currently in an outing
  OutingDto? activeOuting;
  // List of previous outings that the group has been in
  late var outings = <OutingDto>[];
  // Expiry option chosen for group invite link
  String expiryOption = ExpiryOption.never;

  ScrollController scrollController = ScrollController();

  // For the menu options
  static const String ABOUT  = "About";
  static const String SEE_PAST_OUTINGS = "See past outings";
  static const String INVITE_LINK = "Invite Link";
  static const String JIO = "Jio";
  static const String KICK = "Kick";
  static const String LEAVE = "Leave";

  @override
  void initState() {
    super.initState();
    updateMessages();
  }

  void updateMessages() async {
    await messageService.getMessages(widget.chatGroup.id)
      .then((value) {
        setState(() {
          messages = value.body!;
        });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildAppBar(),
    body: Stack(
      children: <Widget>[
        Column(
          children: [
            buildMessageList(messages),
            buildInputWidget()
          ],
        )
      ],
    ),
  );

  AppBar buildAppBar() {
    return AppBar(
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
          onPressed: () async {
            var response = await outingService.getActiveOuting(GetActiveOutingDto(widget.chatGroup.id));
            if (response.isOk) {
              activeOuting = response.body;
            } else {

            }
            if (activeOuting == null) {
              Get.to(() => CreateOutingPage(groupId: widget.chatGroup.id));
            } else {
              Get.to(() => OutingPage(outing: activeOuting!, isActive: true));
            }
          },
          icon: const Icon(
              Icons.assignment
          ),
        ),
        buildMenuOptions()
      ],
    );
  }


  /// Solution to dialog closing immediately in a pop up menu
  /// https://stackoverflow.com/questions/69939559/showdialog-bug-dialog-isnt-triggered-from-popupmenubutton-in-flutter
  Widget buildMenuOptions() {
    return PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert,
        ),
        onSelected: (value) async {
          switch (value) {
            case INVITE_LINK:
              return showDialog(context: context, builder: buildCreateGroupInviteWidget);
            default:
              throw UnimplementedError();
          }
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuItem<String>>[
            PopupMenuItem(
                onTap: () {
                  // TODO: Display group description, same thing as above
                },
                value: ABOUT,
                child: const Text(ABOUT)
            ),
            PopupMenuItem(
                onTap: () {
                  viewPastOutings();
                },
                value: SEE_PAST_OUTINGS,
                child: const Text(SEE_PAST_OUTINGS)
            ),
            const PopupMenuItem(
              value: JIO,
              child: Text(JIO),
            ),
            const PopupMenuItem(
              value: INVITE_LINK,
              child: Text(INVITE_LINK)
            ),
            PopupMenuItem(
                onTap: () {
                  // TODO: Kick people
                },
                value: KICK,
                child: const Text(KICK)
            ),
            PopupMenuItem(
                onTap: () {
                  // TODO: Leave group
                },
                value: LEAVE,
                child: const Text(LEAVE)
            ),
          ];
        }
    );
  }

  Widget buildCreateGroupInviteWidget(BuildContext context) {
    return AlertDialog(
      title: const Text("Choose when your invite link expires"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GroupButton<String>(
            buttons: [ExpiryOption.oneHour, ExpiryOption.oneDay, ExpiryOption.never],
            onSelected: (selected, index, isSelected) {
              setState(() {
                expiryOption = selected;
              });
              return selected;
            },
            maxSelected: 1,
          ),
          ElevatedButton(
              onPressed: () {
                createGroupInvite();
              },
              child: const Text("Create link!")
          ),
        ],
      ),
    );
  }

  void createGroupInvite() async {
    print(expiryOption);
    print(widget.chatGroup.id);
    CreateGroupInviteDto dto = CreateGroupInviteDto(expiryOption, widget.chatGroup.id);
    var response = await groupService.getGroupInvite(dto);
    navigator?.pop();
    if (response.isOk && response.body != null) {
      String inviteLink = response.body!.url;
      Get.defaultDialog(
        title: "Invite link",
        content: Column(
          children: <Widget>[
            Text(
              inviteLink,
              textAlign: TextAlign.center,
            ),
            IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteLink));
                  navigator?.pop();
                },
                icon: const Icon(Icons.content_copy)
            )
          ],
        )
      );
    } else {
      Get.snackbar(
        "Error",
        "We ran into an error obtaining your group invite link",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }



  void viewPastOutings() {
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


  Widget buildMessageList(List<MessageDto> messages) {
    return Expanded(
        child: ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(10.0),
          itemBuilder: (context, index) => buildMessage(messages[messages.length - 1 - index]),
          itemCount: messages.length,
          controller: scrollController,
        )
    );
  }


  Widget buildMessage(MessageDto message) {
    bool isUser = message.user.username == widget.userSummaryDto.username;
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
                  TimeUtil.formatForChatGroup(message.sentAt),
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
                  sendMessage(textEditingController.value.text);
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

  void sendMessage(String message) async {
    await messageService.sendMessage(SendMessageDto(message, widget.chatGroup.id));
    updateMessages();
  }


}
