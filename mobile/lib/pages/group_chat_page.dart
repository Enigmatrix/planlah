import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mobile/dto/chat.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/pages/friend_components.dart';
import 'package:mobile/pages/outing_page.dart';
import 'package:mobile/pages/profile_page.dart';
import 'package:mobile/pages/view_all_outings.dart';
import 'package:mobile/services/group.dart';
import 'package:mobile/services/message.dart';
import 'package:mobile/services/outing.dart';
import 'package:group_button/group_button.dart';
import 'package:mobile/services/session.dart';
import 'package:mobile/utils/errors.dart';
import 'package:mobile/widgets/JioGroupWidget.dart';
import 'package:mobile/widgets/wait_widget.dart';

import '../dto/group_invite.dart';
import '../dto/user.dart';
import 'chat_components.dart';
import 'create_outing_page.dart';

class GroupChatPage extends StatefulWidget {
  GroupSummaryDto chatGroup;
  UserProfileDto userProfile;

  GroupChatPage({
    Key? key,
    required this.chatGroup,
    required this.userProfile,
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

  late var groupMembers = <UserSummaryDto>[];

  ScrollController scrollController = ScrollController();
  StreamSubscription? messagesForGroupSub;

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
    final sess = Get.find<SessionService>();
    updateMessages();
    messagesForGroupSub = sess.groupUpdate(widget.chatGroup.id).listen((event) {
      updateMessages();
      if (!widget.chatGroup.isDm) {
        print("Updating members!");
        updateMembers();
      }
    });
  }

  @override
  void dispose() {
    messagesForGroupSub?.cancel();
    super.dispose();
  }

  void updateMessages() async {
    Response<List<MessageDto>?> resp = await messageService.getMessages(widget.chatGroup.id);
    if (resp.isOk) {
      setState(() {
        messages = resp.body!;
      });
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, resp);
    }
  }

  void updateMembers() async {
    Response<List<UserSummaryDto>?> resp = await groupService.getAllGroupMembers(widget.chatGroup.id);
    if (resp.isOk) {
      setState(() {
        groupMembers = resp.body!;
      });
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, resp);
    }
  }

  /// Used to avoid initialization errors
  Future<Response<List<UserSummaryDto>?>> getGroupMembers() async {
    return await groupService.getAllGroupMembers(widget.chatGroup.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getGroupMembers(),
      builder: (BuildContext context, AsyncSnapshot<Response<List<UserSummaryDto>?>> snapshot) {
        if (snapshot.hasData) {
          if (!snapshot.hasError) {
            groupMembers = snapshot.data!.body!;
            return buildPage();
          } else {
            return const SizedBox.shrink();
          }
        } else {
          return waitWidget();
        }
      }
    );
  }

  Widget buildPage() {
    return Scaffold(
      appBar: buildAppBar(),
      body: Stack(
        children: <Widget>[
          Column(
            children: [
              ChatComponents.buildMessageList(scrollController, messages, widget.userProfile, widget.chatGroup.isDm),
              ChatComponents.buildInputWidget(sendMessage),
            ],
          )
        ],
      ),
    );
  }

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
              if (!mounted) return;
              await ErrorManager.showError(context, response);
              return;
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
    double radius = MediaQuery.of(context).size.width / 4;
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: radius,
            backgroundImage: NetworkImage(widget.chatGroup.imageLink)
          ),
          Text(
            widget.chatGroup.name,
            style: const TextStyle(
              fontSize: 26.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.chatGroup.description
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                  child: Container(
                    alignment: AlignmentGeometry.lerp(null, null, 0.0),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue,
                      borderRadius: BorderRadius.circular(64.0),
                    ),
                    child: const Text(
                      "Group members",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0
                      ),
                    ),
                  ),
              )
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: groupMembers.length,
              itemBuilder: buildGroupMemberList
            ),
          )
        ],
      ),
    );
  }

  Widget buildGroupMemberList(BuildContext context, int index) {
    var user = groupMembers[index];
    if (user.id == widget.userProfile.id) {
      return FriendComponents.buildFriendTile(context, user, () => const ProfilePage(userId: -1));
    } else {
      return FriendComponents.buildFriendTile(context, user, () => ProfilePage(userId: user.id));
    }
  }

  void handleProfile() {
    if (!widget.chatGroup.isDm) {
      showDialog(context: context, builder: buildGroupProfileDialog);
    } else {
      // Get friend's user id
      int userId = getFriend().id;
      Get.to(() => ProfilePage(userId: userId));
    }
  }

  Widget buildGroupTitle() {
    return InkWell(
      onTap: handleProfile,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundImage: NetworkImage(
              widget.chatGroup.isDm ? getFriend().imageLink : widget.chatGroup.imageLink,
            ),
            maxRadius: 20,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.chatGroup.isDm ? getFriend().name : widget.chatGroup.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  UserSummaryDto getFriend() {
    // Used only if in a DM
    if (!widget.chatGroup.isDm) {
      throw ArgumentError.value("Not supported for groups!");
    } else {
      return groupMembers[0].id == widget.userProfile.id ? groupMembers[1] : groupMembers[0];
    }
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
              showDialog(context: context, builder: buildCreateGroupInviteWidget);
              break;
            case ABOUT:
              handleProfile();
              return;
            case SEE_PAST_OUTINGS:
              viewPastOutings();
              return;
            case JIO:
              showDialog(context: context, builder: buildJioGroupWidget);
              return;
            default:
              throw UnimplementedError();
          }
        },
        itemBuilder: buildPopUpMenuItems
    );
  }

  List<PopupMenuItem<String>> buildPopUpMenuItems(BuildContext context) {
    var widgets =  <PopupMenuItem<String>>[
      const PopupMenuItem(
          value: ABOUT,
          child: Text(ABOUT)
      ),
      PopupMenuItem(
          onTap: () {
            viewPastOutings();
          },
          value: SEE_PAST_OUTINGS,
          child: const Text(SEE_PAST_OUTINGS)
      )
    ];
    if (!widget.chatGroup.isDm) {
      widgets.addAll([
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
      ]);
    }
    return widgets;
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

  Widget buildJioGroupWidget(BuildContext context) {
    return JioFriendsToGroupWidget(groupId: widget.chatGroup.id);
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
      if (!mounted) return;
      await ErrorManager.showError(context, response);
    }
  }

  void viewPastOutings() {
    outingService
      .getAllOutings(widget.chatGroup.id)
      .then((value) {
          setState(() {
            if (value.body == null || value.body!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: ListTile(
                  title: Text("Operation not possible: "),
                  subtitle: Text("Your group has not had any outings yet :("),
                ),
                backgroundColor: Colors.deepOrange,
              ));
            } else {
              outings = value.body!;
              Get.to(() => ViewAllOutingsPage(pastOutings: outings));
            }
          });
      });
  }

  void sendMessage(String message) async {
    final resp = await messageService.sendMessage(SendMessageDto(message, widget.chatGroup.id));
    if (!resp.isOk) {
      if (!mounted) return;
      await ErrorManager.showError(context, resp);
    }
  }
}
