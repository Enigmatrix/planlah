import 'package:flutter/material.dart';

import '../dto/outing.dart';

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
      body: ListView.builder(
          itemCount: widget.pastOutings.length,
          itemBuilder: buildOutingCard
      ),
    );
  }

  Widget buildOutingCard(BuildContext context, int id) {
    OutingDto outingDto = widget.pastOutings[id];
    // TODO: Only a temporary way to display the different outings
    return Card(
      child: Text(outingDto.name),
    );
  }
}
