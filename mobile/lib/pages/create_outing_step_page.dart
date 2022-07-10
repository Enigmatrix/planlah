import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lit_relative_date_time/controller/relative_date_format.dart';
import 'package:lit_relative_date_time/lit_relative_date_time.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/dto/outing_step.dart';
import 'package:mobile/model/outing_list.dart';
import 'package:mobile/pages/outing_page.dart';
import 'package:mobile/pages/sign_up_components/fadeindexedstack.dart';
import 'package:time_picker_widget/time_picker_widget.dart';
import 'package:time_range_picker/time_range_picker.dart';

import '../services/outing.dart';
import '../utils/time.dart';

class CreateOutingStepPage extends StatefulWidget {

  OutingDto outing;
  int? placeId;

  CreateOutingStepPage({
    Key? key,
    required this.outing,
    this.placeId
  }) : super(key: key);

  @override
  State<CreateOutingStepPage> createState() => _CreateOutingStepPageState();
}

class _CreateOutingStepPageState extends State<CreateOutingStepPage> {

  String stepDesc = "";
  DateTime? voteDeadline;
  DateTime? date;
  TimeRange? timeRange;
  int? placeId;

  final outingService = Get.find<OutingService>();

  final _nameKey = GlobalKey<FormFieldState>();
  final _descKey = GlobalKey<FormFieldState>();

  final textPadding = const EdgeInsets.only(
    left: 20.0,
    right: 20.0,
    top: 5.0,
    bottom: 5.0,
  );

  @override
  void initState() {
    super.initState();
    placeId = widget.placeId;
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
              scale: 0.5,
            ),
            buildFirstPage(context),
          ],
        ),
      )
    );
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
        buildDatetimeRangeButton(context),
        buildCreateOutingStepButton()
      ],
    );
  }

  Widget buildOutingDescriptionTextBox() {
    return Padding(
      padding: textPadding,
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

  fmtDate(DateTime d) => DateFormat("MM/dd").format(d.toLocal());

  Widget buildDatetimeRangeButton(BuildContext context) {
    final firstDate = DateTime.parse(widget.outing.start).toLocal();
    final lastDate = DateTime.parse(widget.outing.end).toLocal();

    final datePicker = TextButton(onPressed: () async {
      final chosenDate = await showDatePicker(context: context,
        firstDate: firstDate,
        lastDate: lastDate,
        initialDate: firstDate,
      );
      setState(() {
        if (chosenDate != null) {
          date = chosenDate;
        }
      });
    }, child: Text(fmtDate(date!)));

    final timePicker = TextButton(onPressed: () async {
      final chosenTimeRange = await showTimeRangePicker(context: context);
      // only because lastDate is a required parameter
      setState(() {
        timeRange = chosenTimeRange;
      });
    }, child: Text(timeRange == null  ? "When?" : "${timeRange!.startTime.format(context)} to ${timeRange!.endTime.format(context)}"));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        datePicker,
        timePicker
      ],
    );
  }

  Widget buildCreateOutingStepButton() {
    return ElevatedButton(
        onPressed: () {
          if (_nameKey.currentState!.validate() &&
              _descKey.currentState!.validate() &&
              date != null &&
              timeRange != null && placeId != null && voteDeadline != null) {
            createOuting();
          } else {
            // TODO thorw error at user face
          }
        },
        child: const Text(
          "Let's go",
          style: TextStyle(
              fontWeight: FontWeight.bold
          ),
        )
    );
  }

  void createOuting() async {

    final startTime = timeRange!.startTime;
    final endTime = timeRange!.endTime;
    final start = DateTime(date!.year, date!.month, date!.day, startTime.hour, startTime.minute);
    final end = DateTime(date!.year, date!.month, date!.day, endTime.hour, endTime.minute);

    var response = await outingService.createOutingStep(CreateOutingStepDto(
      widget.outing.id,
      stepDesc,
      placeId!,
      start.toUtc().toIso8601String(),
      end.toUtc().toIso8601String(),
      voteDeadline!.toUtc().toIso8601String()
    ));

    if (response.isOk && response.body != null) {
      Get.back();
    } else {
      Get.snackbar(
        "Error",
        "We encountered an error creating your outing",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red
      ).show();
    }
  }
}
