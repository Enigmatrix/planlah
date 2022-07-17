import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:duration/duration.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/dto/outing_step.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/pages/create_outing_step_page.dart';
import 'package:mobile/pages/place_profile_page.dart';
import 'package:mobile/pages/create_post.dart';
import 'package:mobile/services/session.dart';
import 'package:mobile/services/user.dart';
import 'package:mobile/utils/errors.dart';
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
  late UserSummaryDto thisUser;

  final userSvc = Get.find<UserService>();
  final outingSvc = Get.find<OutingService>();
  late DateTime currentTime;

  bool showVoting = true;
  StreamSubscription? timerWaitStream;
  StreamSubscription? actingOutingChangeSub;

  @override
  void initState() {
    super.initState();
    final sess = Get.find<SessionService>();

    outing = widget.outing;
    isActive = widget.isActive;

    userSvc.getInfo().then((value) async {
      if (value.isOk) {
        setState(() => {thisUser = value.body!});
      } else {
        if (!mounted) return;
        await ErrorManager.showError(context, value);
      }
    });


    if (isActive) {

      // Watch for changes to active outing
      actingOutingChangeSub = sess.activeOuting(outing.groupId).listen((event) async {
        final resp = await outingSvc.getActiveOuting(GetActiveOutingDto(outing.groupId));
        if (resp.isOk) {
          setState(() {
            outing = resp.body!;
          });
        } else {
          if (!mounted) return;
          await ErrorManager.showError(context, resp);
        }
      });

      currentTime = DateTime.now().toLocal();
      //// Wait until voteDeadline to update state
      updateShowVoting();
      // Run a 1 second periodic timer until the voteDeadline
      timerWaitStream = Stream.periodic(const Duration(seconds: 1)).listen((_) {
        updateShowVoting();
        // trigger view refresh
        setState(() {
          currentTime = DateTime.now().toLocal();
        });
      });
    } else {
      showVoting = false;
    }
  }

  void updateShowVoting() {
    setState(() {
      final _showVoting = DateTime.now().isBefore(pdate(outing.voteDeadline));
      showVoting = _showVoting;
    });
  }

  @override
  void dispose() {
    super.dispose();
    // these are Futures ... wtv
    timerWaitStream?.cancel();
    actingOutingChangeSub?.cancel();
  }

  final bottomPadding =
      100.0; // show the floatingActionBar without hiding any content
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
              Text(
                "  Create a new Step using ",
                style: TextStyle(fontSize: 20.0),
              ),
              Icon(Icons.add, size: 32.0),
            ],
          )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final range =
        "${fmtDate(pdate(outing.start))} - ${fmtDate(pdate(outing.end))}";
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
                stops: const [
              0.2,
              0.7
            ],
                colors: [
              Colors.grey[300]!,
              Colors.blue[100]!,
            ])),
        child: outing.steps.isEmpty
            ? buildOutingStepHelp()
            : CustomScrollView(
                slivers: [
                  if (showVoting)
                    SliverToBoxAdapter(
                        child: buildVoteDeadlineTimeline(
                            context, outing.steps.isEmpty)),
                  SliverList(
                      delegate: TimelineTileBuilderDelegate(
                    (context, index) {
                      return buildOutingStepTimelineTile(
                          context,
                          outing.steps[index],
                          index == outing.steps.length - 1);
                    },
                    childCount: outing.steps.length,
                  )),
                ],
              ),
      ),
    );
  }

  Widget buildVoteDeadlineTimeline(BuildContext context, bool noSteps) {
    return TimelineTile(
      node: TimelineNode(
        indicator: Container(
          decoration: const BoxDecoration(),
          child: Card(
              color: Colors.indigo[400],
              shape: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(fmtDateTime(outing.voteDeadline),
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[400]!)),
              )),
        ),
        startConnector: const SolidLineConnector(),
        endConnector: const SolidLineConnector(),
      ),
      nodeAlign: TimelineNodeAlign.start,
      contents: Card(
        color: Colors.indigo[500]!,
        elevation: 8.0,
        margin: EdgeInsets.only(
            right: 12.0, left: 4.0, bottom: noSteps ? bottomPadding : 0.0),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: ListTile(
            leading: Icon(
              Icons.how_to_vote,
              color: Colors.grey[500]!,
            ),
            title: Text(
              "Vote ends at ${durTill(DateTime.now(), pdate(outing.voteDeadline))}",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.0,
                  color: Colors.grey[300]!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            dense: true,
            minVerticalPadding: 0,
            minLeadingWidth: 0,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }

  Widget buildOutingStepTimelineTileConflicts(
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
          margin: EdgeInsets.only(
              top: 12.0, right: 8.0, bottom: isLast ? bottomPadding : 0.0),
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
    return durTill(s, e);
  }

  String durTill(DateTime s, DateTime e) {
    var odiff = e.difference(s);
    var diff = Duration(
        days: odiff.inDays, hours: odiff.inHours, minutes: odiff.inMinutes);
    if (diff < const Duration(minutes: 5)) {
      diff = Duration(minutes: odiff.inMinutes, seconds: odiff.inSeconds);
    }
    return prettyDuration(diff, abbreviated: true);
  }

  Widget buildOutingStepTimelineTileNoConflicts(
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
        padding: EdgeInsets.only(
            top: 12.0, right: 8.0, bottom: isLast ? bottomPadding : 0.0),
        child: buildOutingStepCard(step, false),
      ),
    );
  }

  static const titleStyle =
      TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);

  Widget buildVotePart(bool vote, OutingStepDto step) {
    var votes = step.outingStepVoteDtos;
    const border =
        CircleBorder(side: BorderSide(color: Colors.indigo, width: 1));
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

    bool hasUserVoted =
        votes.any((element) => element.userSummaryDto.id == thisUser.id);

    var voteBtnChild = ElevatedButton.icon(
      onPressed: () async {
        final resp = await outingSvc.vote(step.id, vote);
        if (!resp.isOk) {
          if (!mounted) return;
          await ErrorManager.showError(context, resp);
        }
      },
      icon: Icon(voteIcon, color: hasUserVoted ? voteBg : voteColor),
      label: Text(voteText,
          style: TextStyle(color: hasUserVoted ? voteBg : voteColor)),
      style: ButtonStyle(
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                  color: hasUserVoted ? voteBg : voteColor, width: 1.0))),
          backgroundColor:
              MaterialStateProperty.all(!hasUserVoted ? voteBg : voteColor)),
    );

    int shown = 3;
    double shift = 16.0;
    int more = votes.length - shown;
    votes = votes.take(shown).toList();

    List<Widget> elements;

    if (votes.isEmpty) {
      elements = [Positioned(
          top: 0,
          bottom: 0,
          right: !vote ? 0 : null,
          left: vote ? 0 : null,
          child: const Card(
            elevation: 2.0,
            color: Color.fromARGB(0xff, 0xEE, 0xEE, 0xEE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(
                child: Text("NO VOTES",
                      style: TextStyle(fontSize: 11.0, color: Colors.blue, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ))];
    } else {
      elements = votes
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
                child: Text("+$more",
                    style: const TextStyle(fontSize: 11.0, color: Colors.blue)),
              ),
            ));
        elements.add(restCount);
      }
    }

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 32,
                child: Row(mainAxisSize: MainAxisSize.max, children: [
                  Expanded(
                    child: Stack(children: elements),
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
            InkWell(
              onTap: () {
                Get.to(() => PlaceProfilePage(place: step.place));
              },
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text(
                      "${step.description} @ ${step.place.name}",
                      style: titleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    contentPadding:
                    const EdgeInsets.only(left: 12.0, right: 12.0, top: 4.0),
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
                ],
              ),
            ),
            if (showVoting)
              buildVoteCompletePart(step)
            else if (pdate(step.start).isBefore(currentTime) && pdate(step.end).isAfter(currentTime))
              buildInProgressPart(step)
            else if (pdate(step.start).isBefore(currentTime) && pdate(step.end).isBefore(currentTime))
              buildCompletedPart(step)
            else
              buildNotYet(step)
          ],
        ));
  }

  Widget buildNotYet(OutingStepDto step) {
    return buildStatusPart(const Icon(Icons.circle_outlined, color: Colors.blue), "Soon", false, step);
  }

  Widget buildInProgressPart(OutingStepDto step) {
    return buildStatusPart(const Icon(Icons.timer, color: Colors.deepOrange), "Right now!", true, step);
  }

  Widget buildStatusPart(Icon statusIcon, String statusText, bool showCreatePost, OutingStepDto step) {
    return ListTile(
      leading: statusIcon,
      title: Text(statusText),
      dense: false,
      visualDensity: VisualDensity.compact,
      horizontalTitleGap: 0,
      trailing: !showCreatePost ? null : ElevatedButton.icon(
          onPressed: () async {
            await createPost(step.id);
          },
          icon: const Icon(Icons.post_add),
          label: const Text("Post!"),
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.deepOrange)
          )
      ),
    );
  }

  Future<void> createPost(int outingStepId) async {
    var createPostDialog = AlertDialog(
        title: const Text(
          "Create a new Post",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20
          ),
        ),
        content: CreatePostPage(outingStepId: outingStepId,)
    );

    await showDialog(context: context, builder: (builder) => createPostDialog);
  }

  Widget buildCompletedPart(OutingStepDto step) {
    return buildStatusPart(const Icon(Icons.check, color: Colors.green), "Done", true, step);
  }

  Widget buildVoteCompletePart(OutingStepDto step) {
    final yesCount = step.outingStepVoteDtos.where((element) => element.vote).length;
    final noCount = step.outingStepVoteDtos.length - yesCount;
    final yesPercent = yesCount / (yesCount + noCount);
    // TODO show undecidedCount

    double round = 10.0;
    double count1 = yesPercent - round;
    double count2 = yesPercent + round;

    count1 = max(0, count1);
    count2 = min(100, count2);

    if (yesCount == 0 && noCount != 0) {
      count1 = 0;
      count2 = 0;
    } else if (noCount == 0) {
      count1 = 1.0;
      count2 = 1.0;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [count1, count2],
                    colors: [
                      Colors.green[300]!,
                      Colors.red[300]!,
                    ])),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            buildVotePart(true, step),
            buildVotePart(false, step),
          ],
        )
      ],
    );
  }

  Widget buildOutingStepTimelineTile(
      BuildContext context, List<OutingStepDto> conflictingSteps, bool isLast) {
    if (conflictingSteps.length == 1) {
      return buildOutingStepTimelineTileNoConflicts(
          context, conflictingSteps[0], isLast);
    } else {
      return buildOutingStepTimelineTileConflicts(
          context, conflictingSteps, isLast);
    }
  }
}
