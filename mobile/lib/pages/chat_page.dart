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

import '../dto/group_invite.dart';
import '../dto/user.dart';
import 'CreateOutingPage.dart';
import 'chat_components.dart';

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
  late ExpiryOption expiryOption;

  ScrollController scrollController = ScrollController();

  // For the menu options
  static const String ABOUT = "About";
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
    Response<List<MessageDto>?> resp = await messageService.getMessages(widget.chatGroup.id);
    if (resp.isOk) {
      setState(() {
        messages = resp.body!;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: buildAppBar(),
    body: Stack(
      children: <Widget>[
        Column(
          children: [
            ChatComponents.buildMessageList(scrollController, messages, widget.userSummaryDto),
            ChatComponents.buildInputWidget(sendMessage),
          ],
        )
      ],
    ),
  );

  AppBar buildAppBar() {
    return AppBar(
      title: buildGroupTitle(),
      actions: <Widget>[
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

  Widget buildGroupProfileDialog(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 2,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.chatGroup.imageLink)
              )
            ),
          ),
          Text(
              widget.chatGroup.name
          ),
          Text(
            widget.chatGroup.description
          ),
          const SizedBox(height: 4)
        ],
      ),
    );
  }

  Widget buildGroupTitle() {
    return InkWell(
      onTap: () {
        // TODO: Group description
        showDialog(context: context, builder: buildGroupProfileDialog);
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
                  showDialog(context: context, builder: buildGroupProfileDialog);
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
            buttons: [ExpiryOption.OneHour.userText, ExpiryOption.OneDay.userText, ExpiryOption.Never.userText],
            onSelected: (selected, index, isSelected) {
              setState(() {
                switch (index) {
                  case 0:
                    expiryOption = ExpiryOption.OneHour;
                    break;
                  case 1:
                    expiryOption = ExpiryOption.OneDay;
                    break;
                  case 2:
                    expiryOption = ExpiryOption.Never;
                    break;
                }
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

  void sendMessage(String message) async {
    await messageService.sendMessage(SendMessageDto(message, widget.chatGroup.id));
    updateMessages();
  }


}
