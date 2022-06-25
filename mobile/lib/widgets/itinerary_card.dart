import "package:flutter/material.dart";
import 'package:mobile/model/outing_steps.dart';

import '../dto/outing.dart';

class ItineraryCard extends StatefulWidget {
  OutingStepDto outingStep;

  ItineraryCard({
    Key? key,
    required this.outingStep
  }) : super(key: key);

  @override
  State<ItineraryCard> createState() => _ItineraryCardState();
}

class _ItineraryCardState extends State<ItineraryCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          Expanded(
              child: InkWell(
                onTap: () {
                  // TODO: Add location info
                  showDialog(
                      context: context,
                      builder: buildAboutPlace
                  );
                },
                child: Column(
                  children: <Widget>[
                    Text(widget.outingStep.name),
                    // TODO: Temporary
                    Image.network("https://cdn.britannica.com/86/182086-050-5FB81069/singer-Taylor-swift-2013.jpg")
                  ],
                ),
              )
          ),
          InkWell(
            onTap: () {
              // TODO: Add Google Maps navigation
            },
            child: Row(
              children: <Widget>[
                const Icon(
                    Icons.near_me
                ),
                // TODO: Temporary
                const Text(
                    "5 morbins from previous"
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildAboutPlace(BuildContext context) {
    // TODO: Actually build the dialog with a list of reviews
    return AlertDialog(
      title: Text(
        widget.outingStep.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20
        ),
      ),
      content: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                  widget.outingStep.description
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                      Icons.check
                  ),
                  label: const Text("Okay")
              ),
              TextButton.icon(
                  onPressed: () {
                    // TODO: Leave a review
                  },
                  icon: const Icon(
                      Icons.reviews
                  ),
                  label: const Text("Review")
              )
            ],
          )
        ],
      )
    );
  }
}
