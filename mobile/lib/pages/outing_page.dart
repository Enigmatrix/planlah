import 'package:flutter/material.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/main.dart';
import 'package:mobile/model/chat_group.dart';
import 'package:mobile/widgets/itinerary_card.dart';
import 'package:timelines/timelines.dart';

import '../model/outing_list.dart';
import '../model/outing_steps.dart';

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
        itemCount: widget.outing.getSize() + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == widget.outing.getSize()) {
            if (widget.isActive) {
              return buildVotingCard();
            } else {
              return const Text("End of your outing");
            }
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
              border: (index == widget.outing.getCurrentOuting())
                  ? Border.all(color: Colors.redAccent.shade700)
                  : Border.all(color: Colors.blueAccent.shade100)
          ),
          child: Text(
              formatTime(widget.outing.getOutingStep(index))
          ),
        ),
        startConnector: getStartConnector(index),
        endConnector: getEndConnector(index),
      ),
      nodeAlign: TimelineNodeAlign.start,
      contents: ItineraryCard(
        outingStep: widget.outing.getOutingStep(index),
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
