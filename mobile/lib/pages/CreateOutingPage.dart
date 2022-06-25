import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/model/outing_list.dart';
import 'package:mobile/pages/outing_page.dart';
import 'package:mobile/pages/sign_up_components/fadeindexedstack.dart';

import '../services/outing.dart';

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

  var _outing_name = "";
  var _outing_desc = "";

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
        ElevatedButton(
            onPressed: () {
              if (_nameKey.currentState!.validate() && _descKey.currentState!.validate()) {
                createOuting();
              }
            },
            child: const Text(
              "Let's go",
              style: TextStyle(
                fontWeight: FontWeight.bold
              ),
            )
        )
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
                _outing_name = value;
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
                _outing_desc = value;
              }
          );
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  void createOuting() async {

    await outingService.create(CreateOutingDto(
      _outing_name,
      _outing_desc,
      widget.groupId
    ));
    // TODO: Retrieve the outing
    outing = Outing.getOuting();
    Get.off(OutingPage(outing: outing));
  }
}
