import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:get/get.dart';
import 'package:intl/date_time_patterns.dart';
import 'package:intl/intl.dart';
import 'package:lit_relative_date_time/lit_relative_date_time.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/dto/outing_step.dart';
import 'package:mobile/dto/place.dart';
import 'package:mobile/model/location.dart';
import 'package:mobile/pages/find_place.dart';
import 'package:mobile/services/place.dart';
import 'package:time_range_picker/time_range_picker.dart';

import '../services/outing.dart';

class CreateOutingStepPage extends StatefulWidget {
  final OutingDto outing;
  final PlaceDto? initialPlace;

  CreateOutingStepPage({Key? key, required this.outing, this.initialPlace})
      : super(key: key);

  @override
  State<CreateOutingStepPage> createState() => _CreateOutingStepPageState();
}

class _CreateOutingStepPageState extends State<CreateOutingStepPage> {
  String stepDesc = "";
  DateTime? voteDeadline;
  DateTime? date;
  TimeRange? timeRange;
  PlaceDto? place;

  final outingService = Get.find<OutingService>();

  final _descKey = GlobalKey<FormFieldState>();

  final defaultMargin =
      const EdgeInsets.only(top: 8.0, left: 24.0, right: 24.0);

  @override
  void initState() {
    super.initState();
    place = widget.initialPlace;
    date = DateTime.parse(widget.outing.start).toLocal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Image.asset(
            "assets/undraw_Having_fun_re_vj4h.png",
            height: 200.0,
          ),
          buildFirstPage(context),
        ],
      ),
    ));
  }

  Widget buildFirstPage(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text(
          "Create a step",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        buildOutingDescriptionTextBox(),
        buildPlaceSelectionButton(),
        buildDatetimeRangeButton(context),
        buildSelectVoteDeadlineButton(),
        buildCreateOutingStepButton()
      ],
    );
  }

  Widget buildOutingDescriptionTextBox() {
    return Container(
      margin: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0),
      child: TextFormField(
        key: _descKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Description",
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a description for your outing";
          }
          return null;
        },
        onChanged: (value) {
          setState(() {
            stepDesc = value;
          });
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }
  final demoPlace = PlaceDto(
  1,
  "BAM! Restaurant",
  "IDK YET",
  "38 Tras Street #38-40, Singapore 078977 Singapore",
  "https://media-cdn.tripadvisor.com/media/photo-s/10/78/cd/f1/entre-nous-creperie.jpg",
  "38 Tras St, Singapore 078977",
  PlaceType.restaurant,
  Point(1.278406, 103.8442916));

  Widget buildPlaceSelectionButton() {
    // place = demoPlace;
    // place = null;
    if (place == null) {
      return Container(
        margin: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
        clipBehavior: Clip.none,
        child: TextButton(
          style: TextButton.styleFrom(padding: const EdgeInsets.all(4.0)),
          clipBehavior: Clip.none,
          onPressed: () async {
            final chosenPlace = await showDialog<PlaceDto>(context: context, builder: (buildContext) {
              return searchChoosePlaceDialog();
            });
            setState(() {
              place = chosenPlace;
            });
          },
          child: Card(
              shape: RoundedRectangleBorder(
                //<-- SEE HERE
                borderRadius: BorderRadius.circular(8.0),
                side: const BorderSide(color: Colors.grey, width: 0.8),
              ),
              child: const ListTile(
                leading: Icon(Icons.place),
                title: Text("Choose where to go!"),
              )),
        ),
      );
    } else {
      return Card(
          margin: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0, bottom:8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Colors.grey, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 8.0),
                    child: Center(child: Text(place!.name, style: const TextStyle(fontSize: 24.0), textAlign: TextAlign.center,)),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(onPressed: () {
                      setState(() {
                        place = null;
                      });
                    }, icon: const Icon(Icons.close))
                  )
                ],
              ),
              Container(
                padding: EdgeInsets.all(8.0),
                child: CachedNetworkImage(imageUrl: place!.imageLink)
              ),
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        // TODO redir to Google Maps
                      },
                      icon: const Icon(Icons.place)),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right:8.0, bottom: 8.0),
                      child: Text(place!.formattedAddress,),
                    ),
                  )
                ],
              ),
            ],
          ));
    }
  }

  Widget searchChoosePlaceDialog() {
    return const AlertDialog(
      title: Text("Find Places"),
      contentPadding: EdgeInsets.all(16.0),
      content: FindPlaceWidget()
    );
  }

  fmtDate(DateTime d) => DateFormat("MM/dd").format(d.toLocal());

  Widget buildDatetimeRangeButton(BuildContext context) {
    final firstDate = DateTime.parse(widget.outing.start).toLocal();
    final lastDate = DateTime.parse(widget.outing.end).toLocal();

    final datePicker = TextButton(
        onPressed: () async {
          final chosenDate = await showDatePicker(
            context: context,
            firstDate: firstDate,
            lastDate: lastDate,
            initialDate: firstDate,
          );
          setState(() {
            if (chosenDate != null) {
              date = chosenDate;
            }
          });
        },
        child: Text(fmtDate(date!)));

    final timePicker = TextButton(
        onPressed: () async {
          final chosenTimeRange = await showTimeRangePicker(context: context);
          // only because lastDate is a required parameter
          setState(() {
            timeRange = chosenTimeRange;
          });
        },
        child: Text(timeRange == null
            ? "When?"
            : "${timeRange!.startTime.format(context)} to ${timeRange!.endTime.format(context)}"));

    return Card(
      margin: defaultMargin,
      shape: RoundedRectangleBorder(
        //<-- SEE HERE
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: Colors.grey, width: 0.8),
      ),
      child: ListTile(
        leading: const Icon(Icons.timer),
        title: Row(
          children: [datePicker, timePicker],
        ),
      ),
    );
  }

  Widget buildSelectVoteDeadlineButton() {
    Widget child;
    if (voteDeadline == null) {
      child = const Text("Vote Deadline");
    } else {
      final fmt = RelativeDateFormat(Localizations.localeOf(context));
      final rel = RelativeDateTime(dateTime: DateTime.now(), other: voteDeadline!);
      child = Text(fmt.format(rel));
    }
    return Card(
        margin: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0, bottom: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: Colors.grey, width: 0.8),
        ),
      child: ListTile(
        onTap: () async {
          final startTime = DateTime.parse(widget.outing.start).toLocal();
          final chosenVoteDeadline = await DatePicker.showDateTimePicker(context,
              minTime: DateTime.now().toLocal(),
              maxTime: startTime, showTitleActions: true
          );
          setState(() {
            voteDeadline = chosenVoteDeadline;
          });
        },
        leading: const Icon(Icons.how_to_vote),
        title: child,
      )
    );
  }

  Widget buildCreateOutingStepButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
          onPressed: () async {
            if (!_descKey.currentState!.validate()) {
              await showError("Description invalid!");
              return;
            }
            if (date == null) {
              await showError("Please select a date");
              return;
            }
            if (timeRange == null) {
              await showError("Please select a time range");
              return;
            }
            if (place == null) {
              await showError("Please select where to go");
              return;
            }
            if (voteDeadline == null) {
              await showError("Please select a voting deadline");
              return;
            }

            await createOutingStep();
          },
          child: const Text(
            "Let's go",
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
    );
  }

  Future<void> showError(String err) async {
    log(err);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.red,
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white,),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(err, style: const TextStyle(color: Colors.white),),
          ),
        ],
      ),
    ));
    // lmao wtf getx kills itself
    /*await Get.snackbar("Error", err,
        colorText: Colors.white,
        borderRadius: 4.0,
        icon: const Icon(Icons.error_outline),
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red)
        .show();*/
  }

  Future<void> createOutingStep() async {
    final startTime = timeRange!.startTime;
    final endTime = timeRange!.endTime;
    final start = DateTime(
        date!.year, date!.month, date!.day, startTime.hour, startTime.minute);
    var end = DateTime(
        date!.year, date!.month, date!.day, endTime.hour, endTime.minute);
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    var response = await outingService.createOutingStep(CreateOutingStepDto(
        widget.outing.id,
        stepDesc,
        place!.id,
        start.toUtc().toIso8601String(),
        end.toUtc().toIso8601String(),
        voteDeadline!.toUtc().toIso8601String()));

    if (response.isOk) {
      Get.back();
    } else {
      final msg = jsonDecode(response.bodyString!)["message"];
      await showError(msg);
    }
  }
}
