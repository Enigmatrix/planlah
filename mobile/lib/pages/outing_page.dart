import 'package:flutter/material.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/main.dart';
import 'package:mobile/model/chat_group.dart';
import 'package:mobile/pages/suggestion.dart';
import 'package:mobile/widgets/itinerary_card.dart';
import 'package:timelines/timelines.dart';
import 'package:get/get.dart';

import '../model/outing_list.dart';
import '../model/outing_steps.dart';
import 'suggestion.dart';

/// Displays the current outing

class OutingPage extends StatefulWidget {
  OutingDto outing;
  bool isActive;

  OutingPage({
    Key? key,
    required this.outing,
    required this.isActive
  }) : super(key: key);

  @override
  State<OutingPage> createState() => _OutingPageState();
}

class _OutingPageState extends State<OutingPage> {

  OutingDto outingDto = OutingDto(1, "123", "123", 5, "1500", "1800", OutingStepDto.getOutingStepDtos());
  List<OutingStepDto> placesToVote = OutingStepDto.getOutingStepDtos();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Itinerary",
          style: TextStyle(
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverList(
              delegate: TimelineTileBuilderDelegate(
                (BuildContext context, int index) {
                  return buildTimelineTile(index);
                },
                childCount: outingDto.getSize(),
              )
          ),
          SliverList(
              delegate: SliverChildBuilderDelegate(
                buildVotingTab,
                childCount: placesToVote.length + 1,
              )
          )
        ],
      )
    );
  }

  Widget buildVotingTab(BuildContext context, int index) {
    if (index == 0) {
      return Column(
        children: <Widget>[
          const Text(
            "Voting starts here",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26
            ),
          ),
          Card(
            child: ListTile(
              title: Image.network(placesToVote[index].wherePoint),
              ),
            )
        ],
      );
    }
    else if (index == placesToVote.length) {
      return Column(
        children: <Widget>[
          const Text(
            "Suggest a place!",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87
            ),
          ),
          buildSuggestionButton(),
        ],
      );
    } else {
      return Card(
        child: ListTile(
          title: Image.network(placesToVote[index].wherePoint),
        ),
      );
    }
  }
  
  Widget buildSuggestionButton() {
    return TextButton(
        onPressed: () {
          // Suggestion interface
          Get.to(() => SuggestionPage());
        },
        child: Text(
          "Suggest",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent.shade700
          ),
        )
    );
  }

  Widget buildTimelineTile(int index) {
    return TimelineTile(
      node: TimelineNode(
        indicator: Container(
          decoration: BoxDecoration(
              border: (index == widget.outing.getCurrentOuting())
                  ? Border.all(color: Colors.redAccent.shade700)
                  : Border.all(color: Colors.blueAccent.shade100)
          ),
          child: Text(
              formatTime(outingDto.getOutingStep(index))
          ),
        ),
        startConnector: getStartConnector(index),
        endConnector: getEndConnector(index),
      ),
      nodeAlign: TimelineNodeAlign.start,
      contents: ItineraryCard(
        outingStep: outingDto.getOutingStep(index),
      ),
      oppositeContents: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Opposite Content"),
      ),
    );
  }
  
  Widget? getStartConnector(int index) {
    if (index == 0) {
      return null;
    } else if (index <= widget.outing.getCurrentOuting()) {
      return const DashedLineConnector();
    } else {
      return const SolidLineConnector();
    }
  }

  Widget? getEndConnector(int index) {
    if (index >= widget.outing.getCurrentOuting()) {
      return null;
    } else if (index < widget.outing.getCurrentOuting()) {
      return const DashedLineConnector();
    } else {
      return const SolidLineConnector();
    }
  }
  
  String formatTime(OutingStepDto outingStep) {
    return "${outingStep.start} - ${outingStep.end}";
  }
}
