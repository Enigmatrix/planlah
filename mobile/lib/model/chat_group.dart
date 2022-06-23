
// TODO: Add
import 'package:mobile/model/group.dart';
import 'package:mobile/model/user.dart';

import 'chat_message.dart';
import 'location.dart';

class ChatGroup {
  final String groupId;
  final String groupName;
  final String mostRecentText;
  final String time;
  final String photoUrl;
  final String description;
  final bool isMessageRead;
  List<ChatMessage> messages;

  ChatGroup({
      required this.groupId,
      required this.groupName,
      required this.mostRecentText,
      required this.time,
      required this.photoUrl,
      required this.description,
      required this.isMessageRead,
      required this.messages,
  });

  GroupInfo getGroupInfo() {
    // This should be legit.
    return GroupInfo(
        owner: UserInfo(
            name: "Bruno Mars",
            imageUrl: "https://www.biography.com/.image/c_fill%2Ccs_srgb%2Cfl_progressive%2Ch_400%2Cq_auto:good%2Cw_620/MTg4NTc2ODg1MjEzNTA1MTQw/gettyimages-134315104.jpg"
        ),
        members: <UserInfo>[
          UserInfo(
              name: "Sasha Obama",
              imageUrl: "https://media.allure.com/photos/5aeb12dfbf1d634fcf6f718e/1:1/w_3455,h_3455,c_limit/SWNS_SASHA_OBAMA_14.jpg"
          )
        ],
        currentLocation: LocationInfo(
            name: "Pyongyang City",
            imageUrl: "https://cms.qz.com/wp-content/uploads/2018/05/north-korea-leader-kim-jong-un-in-pyongyang-e1527666918109.jpg?quality=75&strip=all&w=1600&h=900&crop=1"
        )
    );
  }

  static ChatGroup fromJson(json) => ChatGroup(
      groupId: json["groupId"],
      groupName: json["groupName"],
      mostRecentText: json["mostRecentText"],
      time: json["time"],
      photoUrl: json["photoUrl"],
      description: json["description"],
      isMessageRead: true,
      messages: getChatMessages()
  );

  // TODO: Temporary
  static List<ChatMessage> getChatMessages() {
    const data = [
      {
        "byId": "1",
        "content": "Hello, I am John!",
        "timestamp": "15 Aug 22:30"
        // "timestamp": "2022-05-30*13:23:55"
      },
      {
        "byId": "2",
        "content": "Hi John, how are you?",
        "timestamp": "15 Aug 22:31"
        // "timestamp": "2022-05-30*13:23:59"
      },
      {
        "byId": "1",
        "content": "I am learning Flutter right now!",
        // "timestamp": "2022-05-30*13:24:05"
        "timestamp": "15 Aug 22:32"
      },
      {
        "byId": "2",
        "content": "Wow! Flutter is so cool!",
        // "timestamp": "2022-05-30*13:24:14"
        "timestamp": "15 Aug 22:34"
      },
    ];

    return data.map<ChatMessage>(ChatMessage.fromJson).toList();
  }

  @override
  String toString() {
    return "i am not null";
  }
}