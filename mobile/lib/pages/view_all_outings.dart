import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/pages/outing_page.dart';

import '../dto/outing.dart';
import 'package:get/get.dart';

class ViewAllOutingsPage extends StatefulWidget {

  List<OutingDto> pastOutings;

  ViewAllOutingsPage({
    Key? key,
    required this.pastOutings,
  }) : super(key: key);

  @override
  State<ViewAllOutingsPage> createState() => _ViewAllOutingsPageState();
}

class _ViewAllOutingsPageState extends State<ViewAllOutingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "View your past outings!",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Image.asset("assets/undraw_moments_0y20.png"),
          const Text(
            "Click on any card to relieve your memories"
          ),
          Expanded(
              child: ListView.builder(
                  itemCount: widget.pastOutings.length,
                  itemBuilder: buildOutingCard
              ),
          ),
        ],
      ),
    );
  }

  fmtDate(DateTime d) => DateFormat("MM/dd").format(d.toLocal());
  DateTime pdate(String date) => DateTime.parse(date).toLocal();

  Widget buildOutingCard(BuildContext context, int id) {
    OutingDto outingDto = widget.pastOutings[id];
    final range =
        "${fmtDate(pdate(outingDto.start))} - ${fmtDate(pdate(outingDto.end))}";
    // TODO: Only a temporary way to display the different outings
    return InkWell(
      onTap: () {
        Get.to(() => OutingPage(outing: outingDto, isActive: false));
      },
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.history),
            title: Text("${outingDto.name} ($range)")
        ),
      ),
    );
  }
}
