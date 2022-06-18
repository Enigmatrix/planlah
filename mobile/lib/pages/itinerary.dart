import 'package:flutter/material.dart';
import 'package:mobile/main.dart';
import 'package:mobile/model/chat_group.dart';
import 'package:mobile/widgets/itinerary_card.dart';
import 'package:timelines/timelines.dart';

import '../model/outing_list.dart';
import '../model/outing_steps.dart';

class ItineraryPage extends StatefulWidget {
  OutingList outing;

  ItineraryPage({
    Key? key,
    required this.outing
  }) : super(key: key);

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
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
      body: Timeline.builder(
        itemCount: widget.outing.size() + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == widget.outing.size()) {
            return buildVotingCard();
          } else {
            return buildTimelineTile(index);
          }
        },
      ),
    );
  }

  Widget buildVotingCard() {
    return Card(
      child: Column(
          children: <Widget>[
            const Text(
              "Vote for the next place!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
            ),
            TextButton(
                onPressed: () {
                  // TODO: Voting interface
                },
                child: Text(
                  "Vote",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent.shade700
                  ),
                )
            )
          ],
        ),
      );
  }

  Widget buildTimelineTile(int index) {
    return TimelineTile(
      node: TimelineNode(
        indicator: Container(
          decoration: BoxDecoration(
              border: (index == widget.outing.currentOuting)
                  ? Border.all(color: Colors.redAccent.shade700)
                  : Border.all(color: Colors.blueAccent.shade100)
          ),
          child: Text(
              formatTime(widget.outing.get(index))
          ),
        ),
        startConnector: getStartConnector(index),
        endConnector: getEndConnector(index),
      ),
      nodeAlign: TimelineNodeAlign.start,
      contents: ItineraryCard(
        outingStep: widget.outing.get(index),
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
    } else if (index < widget.outing.currentOuting) {
      return const DashedLineConnector();
    } else {
      return const SolidLineConnector();
    }
  }

  Widget? getEndConnector(int index) {
    if (index == widget.outing.size()) {
      return null;
    } else if (index < widget.outing.currentOuting) {
      return const DashedLineConnector();
    } else {
      return const SolidLineConnector();
    }
  }
  
  String formatTime(OutingStep outingStep) {
    return "${outingStep.whenTimeStart} - ${outingStep.whenTimeEnd}";
  }
}
