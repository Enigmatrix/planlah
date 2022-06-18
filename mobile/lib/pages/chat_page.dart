import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:mobile/model/chat_group.dart';
import 'package:mobile/main.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/pages/itinerary.dart';

import '../model/chat_message.dart';
import '../model/outing_list.dart';
import '../model/outing_steps.dart';

class ChatPage extends StatefulWidget {
  ChatGroup chatGroup;

  ChatPage({
    Key? key,
    required this.chatGroup,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  // TODO: Hardcode for now
  static OutingList getOutings() {
      var lst = [
        OutingStep(
            name: "Gold Mile Complex",
            description: "Filler text 0",
            imageUrl: "https://spj.hkspublications.org/wp-content/uploads/sites/21/2019/02/darren-soh-golden-mile-complex-800x445.jpg",
            whenTimeStart: "0900",
            whenTimeEnd: "1100",
            estimatedTime: "2 mins",
        ),
        OutingStep(
          name: "Golden Mile Spa",
          description: "Filler text 1",
          imageUrl: "https://cdn.archilovers.com/projects/b_730_5bea89b1-da69-4cb3-adc0-7bc4ab1be101.jpg",
          whenTimeStart: "1100",
          whenTimeEnd: "1300",
          estimatedTime: "51 mins",
        ),
        OutingStep(
          name: "KFC",
          description: "Filler text 2",
          imageUrl: "https://shopsinsg.com/wp-content/uploads/2016/07/kfc-fast-food-restaurant-nex-singapore.jpg",
          whenTimeStart: "1300",
          whenTimeEnd: "1500",
          estimatedTime: "53 mins",
        ),
        OutingStep(
          name: "Botanic Gardens",
          description: "Filler text 3",
          imageUrl: "https://www.visitsingapore.com/see-do-singapore/nature-wildlife/parks-gardens/singapore-botanic-gardens/_jcr_content/par-carousel/carousel_detailpage/carousel/item_2.thumbnail.carousel-img.740.416.jpg",
          whenTimeStart: "1500",
          whenTimeEnd: "1600",
          estimatedTime: "53 mins",
        ),
        OutingStep(
          name: "Raffles Hotel",
          description: "Filler text 4",
          imageUrl: "https://www.raffles.com/assets/0/72/651/652/1702/13de7abd-f23b-4754-a517-ef0336aa331b.jpg",
          whenTimeStart: "1600",
          whenTimeEnd: "1800",
          estimatedTime: "53 mins",
        ),
      ];

      return OutingList(outingSteps: lst, currentOuting: 3);
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
                    widget.chatGroup.photoUrl,
                  ),
                  maxRadius: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.chatGroup.groupName,
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
              Get.to(() => ItineraryPage(outing: getOutings()));
            },
            icon: const Icon(
                Icons.assignment
            ),
        ),
        IconButton(
            onPressed: () {
              // TODO: Group actions
            },
            icon: const Icon(
              Icons.more_vert
            )
        )
      ],
    ),
    body: Stack(
      children: <Widget>[
        Column(
          children: [
            buildChat(widget.chatGroup.messages),
            buildInputWidget(),
          ],
        )
      ],
    )
  );


  Widget buildChat(List<ChatMessage> messages) {
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


  Widget buildMessage(ChatMessage message) {
    // Hard code for now
    bool isUser = message.byId == 1;
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
                  message.timestamp,
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
                    color: Colors.white,
                    fontSize: 15.0,
                  ),
                  controller: textEditingController,
                  decoration: const InputDecoration.collapsed(
                    hintText: "Type here",
                    hintStyle: TextStyle(
                        color: Colors.grey
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
