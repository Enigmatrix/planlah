import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lit_relative_date_time/controller/relative_date_format.dart';
import 'package:lit_relative_date_time/lit_relative_date_time.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/dto/outing_step.dart';
import 'package:mobile/dto/place.dart';
import 'package:mobile/model/outing_list.dart';
import 'package:mobile/pages/outing_page.dart';
import 'package:mobile/pages/sign_up_components/fadeindexedstack.dart';
import 'package:mobile/theme.dart';
import 'package:time_picker_widget/time_picker_widget.dart';
import 'package:time_range_picker/time_range_picker.dart';

import '../services/outing.dart';
import '../utils/time.dart';

class CreateOutingStepPage extends StatefulWidget {
  OutingDto outing;
  PlaceDto? place;

  CreateOutingStepPage({Key? key, required this.outing, this.place})
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

  final _nameKey = GlobalKey<FormFieldState>();
  final _descKey = GlobalKey<FormFieldState>();

  final defaultMargin =
      const EdgeInsets.only(top: 8.0, left: 24.0, right: 24.0);

  @override
  void initState() {
    super.initState();
    place = widget.place;
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
        buildPlaceSelectionButton(),
        buildDatetimeRangeButton(context),
        buildOutingDescriptionTextBox(),
        buildCreateOutingStepButton()
      ],
    );
  }

  Widget buildOutingDescriptionTextBox() {
    return Container(
      margin: defaultMargin,
      child: TextFormField(
        key: _descKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Description",
        ),
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

  Widget buildPlaceSelectionButton() {
    place = PlaceDto(
        1,
        "BAM! Restaurant",
        "IDK YET",
        "38 Tras Street #38-40, Singapore 078977 Singapore",
        "https://media-cdn.tripadvisor.com/media/photo-s/10/78/cd/f1/entre-nous-creperie.jpg",
        "38 Tras St, Singapore 078977",
        PlaceType.restaurant,
        Point(1.278406, 103.8442916));
    place = null;
    if (place == null) {
      return Container(
        margin: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
        clipBehavior: Clip.none,
        child: TextButton(
          style: TextButton.styleFrom(padding: const EdgeInsets.all(4.0)),
          clipBehavior: Clip.none,
          onPressed: () async {
            await showDialog(context: context, builder: (buildContext) {
              return searchChoosePlaceDialog();
            });
          },
          child: Card(
              shape: RoundedRectangleBorder(
                //<-- SEE HERE
                borderRadius: BorderRadius.circular(8.0),
                side: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              child: const ListTile(
                leading: Icon(Icons.place),
                title: Text("Choose where to go!"),
              )),
        ),
      );
    } else {
      return Card(
          margin: defaultMargin,
          shape: RoundedRectangleBorder(
            //<-- SEE HERE
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    Text(place!.name, style: const TextStyle(fontSize: 24.0)),
              ),
              CachedNetworkImage(imageUrl: place!.imageLink),
              Row(
                children: [
                  IconButton(
                      onPressed: () {
                        // TODO redir to Google Maps
                      },
                      icon: const Icon(Icons.place)),
                  Flexible(
                    child: Text(place!.formattedAddress),
                  )
                ],
              )
            ],
          ));
    }
  }

  Widget searchChoosePlaceDialog() {
    // TODO
    return SimpleDialog(
      title: const Text("what"),
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
        side: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      child: ListTile(
        leading: const Icon(Icons.timer),
        title: Row(
          children: [datePicker, timePicker],
        ),
      ),
    );
  }

  Widget buildCreateOutingStepButton() {
    return ElevatedButton(
        onPressed: () {
          if (_nameKey.currentState!.validate() &&
              _descKey.currentState!.validate() &&
              date != null &&
              timeRange != null &&
              place != null &&
              voteDeadline != null) {
            createOuting();
          } else {
            // TODO thorw error at user face
          }
        },
        child: const Text(
          "Let's go",
          style: TextStyle(fontWeight: FontWeight.bold),
        ));
  }

  void createOuting() async {
    final startTime = timeRange!.startTime;
    final endTime = timeRange!.endTime;
    final start = DateTime(
        date!.year, date!.month, date!.day, startTime.hour, startTime.minute);
    final end = DateTime(
        date!.year, date!.month, date!.day, endTime.hour, endTime.minute);

    var response = await outingService.createOutingStep(CreateOutingStepDto(
        widget.outing.id,
        stepDesc,
        place!.id,
        start.toUtc().toIso8601String(),
        end.toUtc().toIso8601String(),
        voteDeadline!.toUtc().toIso8601String()));

    if (response.isOk && response.body != null) {
      Get.back();
    } else {
      Get.snackbar("Error", "We encountered an error creating your outing",
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red)
          .show();
    }
  }
}
