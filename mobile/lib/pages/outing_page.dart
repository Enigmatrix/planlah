import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:duration/duration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/dto/outing_step.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/model/user.dart';
import 'package:mobile/pages/create_outing_step_page.dart';
import 'package:mobile/services/user.dart';
import 'package:timelines/timelines.dart';
import 'package:get/get.dart';

import '../services/outing.dart';

/// Displays the current outing

class OutingPage extends StatefulWidget {
  OutingDto outing;
  bool isActive;

  OutingPage({Key? key, required this.outing, required this.isActive})
      : super(key: key);

  @override
  State<OutingPage> createState() => _OutingPageState();
}

class _OutingPageState extends State<OutingPage> {
  // The current card the user has voted on
  int currentVote = -1;

  late OutingDto outing;
  late bool isActive;
  late UserInfo thisUser;

  final userSvc = Get.find<UserService>();
  final outingSvc = Get.find<OutingService>();

  @override
  void initState() {
    super.initState();

    outing = widget.outing;
    isActive = widget.isActive;

    userSvc.getInfo().then((value) {
      if (value.isOk) {
        setState(() => { thisUser = value.body! });
      } else {
        log("userSvc.getInfo err: ${value.bodyString}");
      }
    });
  }

  final bottomPadding = 100.0; // show the floatingActionBar without hiding any content
  fmtDate(DateTime d) => DateFormat("MM/dd").format(d.toLocal());
  DateTime pdate(String date) => DateTime.parse(date).toLocal();

  Widget buildOutingStepHelp() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.help, size: 32.0),
            Text("  Create a new Step using ", style: TextStyle(fontSize: 20.0),),
            Icon(Icons.add, size: 32.0),
          ],
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    final range =
        "${fmtDate(pdate(outing.start))} - ${fmtDate(pdate(outing.end))}";
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        leading:
            isActive ? const Icon(Icons.timeline) : const Icon(Icons.history),
        title: Text("${outing.name} ($range)"),
      ),

      floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Add OutingStep
            Get.to(CreateOutingStepPage(outing: widget.outing));
          },
          child: const Icon(Icons.add)),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.2, 0.7],
                colors: [
              Colors.grey[100]!,
              Colors.blue[100]!,
            ])),
        child: outing.steps.isEmpty ? buildOutingStepHelp() :
          CustomScrollView(
            slivers: [
              SliverList(
                  delegate: TimelineTileBuilderDelegate(
                        (context, index) {
                      return buildTimelineTile(context, outing.steps[index], index == outing.steps.length - 1);
                    },
                    childCount: outing.steps.length,
                  )
              ),
            ],
          ),
        ),
    );
    return Text("");
  }

  Widget buildTimelineTileConflicts(
      BuildContext context, List<OutingStepDto> conflictingSteps, bool isLast) {
    conflictingSteps.sort((a, b) => pdate(a.start).compareTo(pdate(b.start)));
    final step = conflictingSteps[0];
    return TimelineTile(
        node: TimelineNode(
          indicator: Container(
            decoration: const BoxDecoration(),
            child: Card(
                shape: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(fmtDateTime(step.start),
                      style: const TextStyle(fontSize: 12.0)),
                )),
          ),
          startConnector: const SolidLineConnector(),
          endConnector: const SolidLineConnector(),
        ),
        nodeAlign: TimelineNodeAlign.start,
        contents: Card(
          color: Colors.orange,
          elevation: 8.0,
          margin: EdgeInsets.only(top: 12.0, right: 8.0, bottom: isLast ? bottomPadding : 0.0),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.warning),
                  title: Text(
                    "CONFLICTS",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                  ),
                  dense: true,
                  minVerticalPadding: 0,
                  minLeadingWidth: 0,
                  visualDensity: VisualDensity.compact,
                ),
                Column(
                  children: conflictingSteps
                      .map((step) => buildOutingStepCard(step, true))
                      .toList(),
                ),
              ],
            ),
          ),
        ));
  }

  String fmtDateTime(String d) {
    final dt = DateTime.parse(d).toLocal();
    return DateFormat("MM/dd\nHH:mm").format(dt);
  }

  String fmtTime(String d) {
    final dt = DateTime.parse(d).toLocal();
    return DateFormat("HH:mm").format(dt);
  }

  String dur(OutingStepDto step) {
    final s = DateTime.parse(step.start).toLocal();
    final e = DateTime.parse(step.end).toLocal();
    return prettyDuration(e.difference(s));
  }

  Widget buildTimelineTileNoConflicts(
      BuildContext context, OutingStepDto step, bool isLast) {
    return TimelineTile(
      node: TimelineNode(
        indicator: Container(
          decoration: const BoxDecoration(),
          child: Card(
              shape: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  fmtDateTime(step.start),
                  style: const TextStyle(fontSize: 12.0),
                ),
              )),
        ),
        startConnector: const SolidLineConnector(),
        endConnector: const SolidLineConnector(),
      ),
      nodeAlign: TimelineNodeAlign.start,
      contents: Padding(
        padding: EdgeInsets.only(top: 12.0, right: 8.0, bottom: isLast ? bottomPadding : 0.0),
        child: buildOutingStepCard(step, false),
      ),
    );
  }

  static const titleStyle =
      TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);

  Widget buildVotePart(bool vote, OutingStepDto step) {
    var votes = step.outingStepVoteDtos;
    const border = CircleBorder(
      side: BorderSide(color: Colors.indigo, width: 1));
    var alignment = MainAxisAlignment.end;
    var voteColor = Colors.red;
    var voteText = "NO";
    var voteIcon = Icons.close;
    var voteBg = Colors.white;

    if (vote) {
      voteColor = Colors.green;
      voteIcon = Icons.check;
      voteText = "YES";
      alignment = MainAxisAlignment.start;
    }

    votes = votes.where((element) => element.vote == vote).toList();

    // for test
    // votes = {
    //   OutingStepVoteDto(
    //       true,
    //       UserSummaryDto(1, "Akash", "akash",
    //           "https://melmagazine.com/wp-content/uploads/2021/01/3a9.png")),
    //   OutingStepVoteDto(
    //       true,
    //       UserSummaryDto(2, "WWE", "wwe",
    //           "https://www.the-sun.com/wp-content/uploads/sites/6/2021/10/OFF-PLAT-JD-GIGACHAD.jpg?strip=all&quality=100&w=1200&h=800&crop=1")),
    //   OutingStepVoteDto(
    //       true,
    //       UserSummaryDto(3, "Akash", "akash",
    //           "https://melmagazine.com/wp-content/uploads/2021/01/3a9.png")),
    //   OutingStepVoteDto(
    //       true,
    //       UserSummaryDto(4, "WWE", "wwe",
    //           "https://www.the-sun.com/wp-content/uploads/sites/6/2021/10/OFF-PLAT-JD-GIGACHAD.jpg?strip=all&quality=100&w=1200&h=800&crop=1")),
    // }.toList();


    bool hasUserVoted = votes.any((element) => element.userSummaryDto.id == thisUser.id);

    var voteBtnChild = ElevatedButton.icon(
      onPressed: () async {
        final resp = await outingSvc.vote(step.id, vote);
        if (resp.isOk) {
          // TODO display voting
        } else {
          log("outingSvc.vote err: ${resp.bodyString}");
        }
      },
      icon: Icon(voteIcon, color: hasUserVoted ? voteBg : voteColor),
      label: Text(voteText, style: TextStyle(color: hasUserVoted ? voteBg : voteColor)),
      style: ButtonStyle(
          shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: hasUserVoted ? voteBg : voteColor, width: 1.0)
              )
          ),
          backgroundColor: MaterialStateProperty.all(!hasUserVoted ? voteBg : voteColor)
      ),
    );

    int shown = 3;
    double shift = 16.0;
    int more = votes.length - shown;
    votes = votes.take(shown).toList();

    final elements = votes
        .asMap()
        .map((i, v) => MapEntry(
            i,
            Positioned(
              top: 0,
              bottom: 0,
              right: !vote ? shift * i : null,
              left: vote ? shift * i : null,
              child: Material(
                elevation: 4.0,
                shape: border,
                child: CircleAvatar(
                  radius: 14.0,
                  backgroundImage:
                      CachedNetworkImageProvider(v.userSummaryDto.imageLink),
                ),
              ),
            )))
        .values
        .toList();

    if (more > 0) {
      final restCount = Positioned(
          top: 0,
          bottom: 0,
          right: !vote ? shift * shown : null,
          left: vote ? shift * shown : null,
          child: Material(
            elevation: 4.0,
            shape: border,
            child: CircleAvatar(
              radius: 14.0,
              backgroundColor: const Color.fromARGB(0x22, 0x22, 0x22, 0x22),
              child: Text("+$more", style: const TextStyle(fontSize: 11.0, color: Colors.blue)),
            ),
          ));
      elements.add(restCount);
    }

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                SizedBox(
                  height: 32,
                child: Row(mainAxisSize: MainAxisSize.max, children: [
                  Expanded(
                    child: Stack(
                      children: elements
                    ),
                  )
                ]),
              ),
            ),
            Row(
              mainAxisAlignment: alignment,
              children: [voteBtnChild],
            )
          ],
        ),
      ),
    );
  }

  Widget buildOutingStepCard(OutingStepDto step, bool isConflicting) {
    return Card(
        elevation: isConflicting ? 2.0 : 8.0,
        color: isConflicting ? Colors.orange[100]! : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("${step.description} @ ${step.place.name}",
                  style: titleStyle, overflow: TextOverflow.ellipsis,),
              subtitle: Row(
                children: [
                  Text(fmtTime(step.start),
                      style: const TextStyle(
                          color: Colors.blueAccent, fontSize: 13.0)),
                  const Text(" till ",
                      style: TextStyle(color: Colors.grey, fontSize: 13.0)),
                  Text(fmtTime(step.end),
                      style: const TextStyle(
                          color: Colors.blueAccent, fontSize: 13.0)),
                  const Text(", ",
                      style: TextStyle(color: Colors.grey, fontSize: 13.0)),
                  Text(dur(step),
                      style:
                          const TextStyle(color: Colors.blue, fontSize: 13.0)),
                ],
              ),
              minVerticalPadding: 0,
              visualDensity: VisualDensity.compact,
              dense: true,
              contentPadding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 4.0),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                leading: const Icon(Icons.place),
                dense: true,
                horizontalTitleGap: 10,
                minLeadingWidth: 0,
                minVerticalPadding: 0,
                // contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                title: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    step.place.formattedAddress.trim(),
                    style: TextStyle(
                        color: Colors.black.withOpacity(0.6), fontSize: 12.0),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200.0),
              child: CachedNetworkImage(
                imageUrl: step.place.imageLink,
                fit: BoxFit.fill,
              ),
            ),
            if (true) // TODO set this!!!!!!
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  buildVotePart(true, step),
                  buildVotePart(false, step),
                ],
              )
          ],
        ));
  }

  Widget buildTimelineTile(
      BuildContext context, List<OutingStepDto> conflictingSteps, bool isLast) {
    if (conflictingSteps.length == 1) {
      return buildTimelineTileNoConflicts(context, conflictingSteps[0], isLast);
    } else {
      return buildTimelineTileConflicts(context, conflictingSteps, isLast);
    }
  }
}
