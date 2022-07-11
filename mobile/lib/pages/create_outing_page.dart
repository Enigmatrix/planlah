import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lit_relative_date_time/controller/relative_date_format.dart';
import 'package:lit_relative_date_time/lit_relative_date_time.dart';
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

  String outingName = "";
  String outingDesc = "";
  DateTimeRange? range;

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
      resizeToAvoidBottomInset: null,
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
        buildDateRangeButton(context),
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
          setState(() {
                outingDesc = value;
          });
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  Widget buildDateRangeButton(BuildContext context) {
    String text;
    Widget icon;
    if (range == null) {
       text = "When's the fun?";
       icon = const Icon(Icons.timelapse_rounded);
    } else {
      final fmt = (DateTime d) => DateFormat("MM/dd").format(d.toLocal());
      text = "${fmt(range!.start)} to ${fmt(range!.end)}";
      icon = const Icon(Icons.edit);
    }

    return ElevatedButton.icon(onPressed: () async {
      final firstDate = DateTime.now();
      // only because lastDate is a required parameter
      var lastDate = DateTime(firstDate.year + 1, firstDate.month, firstDate.day);
      final chosenRange = await showDateRangePicker(context: context,
          firstDate: firstDate,
          lastDate: lastDate,
      );
      setState(() {
        range = chosenRange;
      });
    }, icon: icon, label: Text(text));
  }

  Widget buildCreateOutingButton() {
    return ElevatedButton(
        onPressed: () {
          if (_nameKey.currentState!.validate() &&
              _descKey.currentState!.validate() &&
              range != null) {
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
    final end = range!.end.toUtc().add(const Duration(days: 1));

    var response = await outingService.createOuting(CreateOutingDto(
      outingName,
      outingDesc,
      widget.groupId,
      range!.start.toUtc().toIso8601String(),
      end.toIso8601String(),
    ));

    if (response.isOk) {
      var response = await outingService.getActiveOuting(GetActiveOutingDto(widget.groupId));
      Get.off(OutingPage(outing: response.body!, isActive: true));
    } else {
      log(response.bodyString!);
    }
  }
}
