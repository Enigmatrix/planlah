import "package:flutter/material.dart";
import 'package:mobile/model/outing_steps.dart';

class ItineraryCard extends StatefulWidget {
  OutingStep outingStep;

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
                    Image.network(widget.outingStep.imageUrl)
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
                Text(
                    "${widget.outingStep.estimatedTime} from previous"
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
