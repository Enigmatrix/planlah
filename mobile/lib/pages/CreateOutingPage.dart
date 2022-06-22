import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/model/outing_list.dart';
import 'package:mobile/pages/outing_page.dart';
import 'package:mobile/pages/sign_up_components/fadeindexedstack.dart';

class CreateOutingPage extends StatefulWidget {
  const CreateOutingPage({Key? key}) : super(key: key);

  @override
  State<CreateOutingPage> createState() => _CreateOutingPageState();
}

class _CreateOutingPageState extends State<CreateOutingPage> {

  int _formIndex = 1;

  var _outing_name = "";

  final _nameKey = GlobalKey<FormFieldState>();

  final before = const Icon(
      Icons.navigate_before_rounded
  );

  final next = const Icon(
      Icons.navigate_next_rounded
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Image.asset("assets/undraw_Having_fun_re_vj4h.png"),
          buildFirstPage(context),
        ],
      ),
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
        Padding(
          padding: const EdgeInsets.all(20.0),
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
          ),
        ),
        ElevatedButton(
            onPressed: () {
              if (_nameKey.currentState!.validate()) {
                Get.to(OutingPage(outing: Outing.getOuting()));
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
}
