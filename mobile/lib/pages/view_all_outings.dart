import 'package:flutter/material.dart';
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
      body: Column(
        children: <Widget>[
          Image.asset("assets/undraw_moments_0y20.png"),
          const Text(
            "View your past outings!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30.0,
            ),
          ),
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

  Widget buildOutingCard(BuildContext context, int id) {
    OutingDto outingDto = widget.pastOutings[id];
    // TODO: Only a temporary way to display the different outings
    return InkWell(
      onTap: () {
        Get.to(() => OutingPage(outing: outingDto, isActive: false));
      },
      child: Card(
        child: Text(outingDto.name),
      ),
    );
  }
}
