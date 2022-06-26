import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/model/outing_list.dart';
import 'package:mobile/pages/outing_page.dart';
import 'package:mobile/pages/sign_up_components/fadeindexedstack.dart';
import 'package:time_picker_widget/time_picker_widget.dart';

import '../services/outing.dart';
import '../utils/time.dart';

class CreateOutingPage extends StatefulWidget {

  int groupId;

  CreateOutingPage({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  State<CreateOutingPage> createState() => _CreateOutingPageState();
}

class _CreateOutingPageState extends State<CreateOutingPage> {

  int _formIndex = 1;

  String outingName = "";
  String outingDesc = "";
  String outingStart = DateTime.now().toLocal().toString();
  String outingEnd = "";

  final outingService = Get.find<OutingService>();

  final _nameKey = GlobalKey<FormFieldState>();
  final _descKey = GlobalKey<FormFieldState>();

  late OutingDto outing;

  final textPadding = const EdgeInsets.only(
    left: 20.0,
    right: 20.0,
    top: 5.0,
    bottom: 5.0,
  );

  final before = const Icon(
      Icons.navigate_before_rounded
  );

  final next = const Icon(
      Icons.navigate_next_rounded
  );

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
          "Create an outing",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        buildOutingNameTextBox(),
        buildOutingDescriptionTextBox(),
        buildEndingTimeButton(context),
        buildCreateOutingButton()
      ],
    );
  }

  Widget buildOutingNameTextBox() {
    return Padding(
      padding: textPadding,
      child: TextFormField(
        key: _nameKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Outing Name",
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a name for your outing";
          }
          return null;
        },
        onChanged: (value) {
          setState(
                  () {
                outingName = value;
              }
          );
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  Widget buildOutingDescriptionTextBox() {
    return Padding(
      padding: textPadding,
      child: TextFormField(
        key: _descKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Outing Description",
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a description for your outing";
          }
          return null;
        },
        onChanged: (value) {
          setState(
                  () {
                outingDesc = value;
              }
          );
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  Widget buildEndingTimeButton(BuildContext context) {
    if (outingEnd == "") {
      return buildTimeButton(context, "When will your outing end?");
    } else {
      return Column(
        children: <Widget>[
          Text(
            "Your current outing will end at $outingEnd"
          ),
          buildTimeButton(context, "Change when your outing ends")
        ],
      );
    }
  }

  Widget buildTimeButton(BuildContext context, String label) {
    return ElevatedButton.icon(
        onPressed: () {
          getEndTime(context);
        },
        icon: const Icon(Icons.lock_clock_outlined),
        label: Text(
            label
        )
    );
  }

  void getEndTime(BuildContext context) async {
    TimeOfDay now = TimeOfDay.now();
    showCustomTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        selectableTimePredicate: (time) =>
          time!.hour >= now.hour &&
          time.minute >= now.minute,
        onFailValidation: (context) => Get.snackbar(
          "Invalid time",
          "",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red
        ).show()
    ).then((time) {
      setState(() {
        outingEnd = time!.toString();
        outingEnd = outingEnd.substring(10, 15);
      });
    });
  }

  Widget buildCreateOutingButton() {
    return ElevatedButton(
        onPressed: () {
          if (_nameKey.currentState!.validate() &&
              _descKey.currentState!.validate() &&
              outingEnd != "") {
            createOuting();
          } else if (outingEnd == "") {
              // Seems hard to do the validation on the customTimePicker side
              // so do it here
              Get.snackbar(
                  "Invalid selection",
                  "Please input when your outing ends",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red
              ).show();
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

    print(outingStart);
    print(outingEnd);

    String chosen = DateTime.now().toLocal().toString();
    print(chosen);
    // Change hour
    chosen = chosen.replaceRange(11, 13, outingEnd.substring(0, 2));
    // Change minute
    chosen = chosen.replaceRange(14, 16, outingEnd.substring(3, 5));
    print(chosen);


    var response = await outingService.create(CreateOutingDto(
      outingName,
      outingDesc,
      widget.groupId,
      TimeUtil.formatForDto(outingStart),
      TimeUtil.formatForDto(chosen)
    ));
    var activeOuting;
    if (response.isOk) {
      Get.off(OutingPage(outing: outing, isActive: true));
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
