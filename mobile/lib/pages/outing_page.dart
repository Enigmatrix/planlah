import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/dto/outing_step.dart';
import 'package:mobile/main.dart';
import 'package:mobile/model/chat_group.dart';
import 'package:mobile/pages/create_outing_step_page.dart';
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

  // The current card the user has voted on
  int currentVote = -1;

  late OutingDto outing;
  late bool isActive;

  @override
  void initState() {
    super.initState();

    outing = widget.outing;
    isActive = widget.isActive;
  }

  fmtDate(DateTime d) => DateFormat("MM/dd").format(d.toLocal());
  pdate(String date) => DateTime.parse(date).toLocal();

  @override
  Widget build(BuildContext context) {
    print(outing.steps[1].length);
    final range = "${fmtDate(pdate(outing.start))} - ${fmtDate(pdate(outing.end))}";
    return Scaffold(
      appBar: AppBar(
        leading:  isActive ? const Icon(Icons.place) : const Icon(Icons.history),
        title: Text("${outing.name} ($range)"),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Add OutingStep
            Get.to(CreateOutingStepPage(outing: widget.outing));
          },
          child: const Icon(Icons.add)
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(delegate: TimelineTileBuilderDelegate(
            (context, index) {
              return buildTimelineTile(context, outing.steps[index]);
            },
            childCount: outing.steps.length
          ))
        ],
      ),
    );
    return Text("");
  }

  Widget buildTimelineTileConflicts(BuildContext context, List<OutingStepDto> conflictingSteps) {
    // return TimelineTile(
    //   node: TimelineNode(
    //     indicator: Container(
    //       decoration: BoxDecoration(
    //         // border: (index == widget.outing.getCurrentOuting())
    //         //     ? Border.all(color: Colors.redAccent.shade700)
    //         //     : Border.all(color: Colors.blueAccent.shade100)
    //       ),
    //       child: child,
    //     ),
    //     startConnector: getStartConnector(index),
    //     endConnector: getEndConnector(index),
    //   ),
    //   nodeAlign: TimelineNodeAlign.start,
    //   contents: ItineraryCard(
    //     outingStep: outingDto.getOutingStep(index),
    //   ),
    //   oppositeContents: const Padding(
    //     padding: EdgeInsets.all(8.0),
    //     child: Text("Opposite Content"),
    //   ),
    // );
    return Text("whayt ${conflictingSteps.length}");
  }

  String fmtDateTime(String d) {
    final dt = DateTime.parse(d).toLocal();
    return DateFormat("MM/dd HH:mm").format(dt);
  }

  Widget buildTimelineTileNoConflicts(BuildContext context, OutingStepDto step) {
    return TimelineTile(
      node: TimelineNode(
        indicator: Container(
          decoration: const BoxDecoration(),
          child: Text(fmtDateTime(step.start)),
        ),
        startConnector: const SolidLineConnector(),
        endConnector: const SolidLineConnector(),
      ),
      nodeAlign: TimelineNodeAlign.start,
      contents: buildOutingStepCard(step),
    );
  }

  Widget buildOutingStepCard(OutingStepDto step) {
    return Card(
      child: ListTile(
        title: Text(step.description),
      ),
    );
  }


  Widget buildTimelineTile(BuildContext context, List<OutingStepDto> conflictingSteps) {
    if (conflictingSteps.length == 1) {
      return buildTimelineTileNoConflicts(context, conflictingSteps[0]);
    } else {
      return buildTimelineTileConflicts(context, conflictingSteps);
    }
  }
}
