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

  OutingDto outingDto = OutingDto(1, "123", "123", 5, "1500", "1800", OutingStepDto.getHistoricalOutingStepDtos());
  List<OutingStepDto> placesToVote = OutingStepDto.getVotingStepDtos();
  // The current card the user has voted on
  int currentVote = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (widget.isActive)
              ? "Active: ${widget.outing.name}"
              : "History: ${widget.outing.name}",
          style: const TextStyle(
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
          buildSecondPart()
        ],
      )
    );
  }

  Widget buildSecondPart() {
    if (widget.isActive) {
      return SliverList(
          delegate: SliverChildBuilderDelegate(
            buildVotingTab,
            childCount: placesToVote.length + 1,
          )
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
            (context, index) {
              return const Center(
                child: Text(
                  "End of your outing :)",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  ),
                ),
              );
            },
          childCount: 1
        ),
      );
    }
  }

  final Icon voteIcon = const Icon(Icons.where_to_vote_sharp);

  Widget buildVotingCard(BuildContext context, int index) {
    return Card(
      child: ListTile(
        // TODO: Actually properly do this after milestone 2
        leading: ElevatedButton.icon(
          onPressed: () {
            if (index == currentVote) {

            } else {
              setState(() {
                currentVote = index;
              });
            }
          },
          icon: voteIcon,
          label: buildVoteLabel(index),
          style: ButtonStyle(
              backgroundColor: (index == currentVote)
                  ? MaterialStateProperty.all<Color>(Colors.green)
                  : MaterialStateProperty.all<Color>(Colors.blue)
          )
        ),
        title: InkWell(
          onTap: () {
            showDialog(
                context: context,
                builder: (context) => ItineraryCard.buildAboutPlace(context, placesToVote[index])
            );
          },
          child: Image.network(placesToVote[index].wherePoint),
        ),
      ),
    );
  }

  Widget buildVoteLabel(int index) {
    return Text(
      "Vote",
      style: TextStyle(
        color: (index == currentVote) ? Colors.green : Colors.grey
      ),
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
          buildVotingCard(context, index),
        ],
      );
    }
    else if (index == placesToVote.length) {
      return Column(
        children: <Widget>[
          ElevatedButton.icon(
              onPressed: (){
                // TODO:
                Get.snackbar(
                  "Work in progress",
                  "Bob the builder says hi :)",
                  backgroundColor: Colors.yellow
                ).show();
              },
              icon: voteIcon,
              label: const Text(
                "Confirm your vote!"
              )
          ),
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
      return buildVotingCard(context, index);
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
    } else if (index <= outingDto.getCurrentOuting()) {
      return const DashedLineConnector();
    } else {
      return const SolidLineConnector();
    }
  }

  Widget? getEndConnector(int index) {
    if (index >= outingDto.getCurrentOuting()) {
      return null;
    } else if (index < outingDto.getCurrentOuting()) {
      return const DashedLineConnector();
    } else {
      return const SolidLineConnector();
    }
  }
  
  String formatTime(OutingStepDto outingStep) {
    return "${outingStep.start} - ${outingStep.end}";
  }
}
