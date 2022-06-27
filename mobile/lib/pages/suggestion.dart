import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../dto/outing.dart';


class SuggestionPage extends StatefulWidget {
  const SuggestionPage({Key? key}) : super(key: key);

  @override
  State<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends State<SuggestionPage> {

  List<OutingStepDto> steps = OutingStepDto.getHistoricalOutingStepDtos();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Suggestion",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0
          ),
        ),
      ),
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Here are the best locations for you and your friends",
                style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            const Text(
              "Click on a card to find out more information"
            ),
            Expanded(
                child: ListView.builder(
                  itemCount: steps.length,
                  itemBuilder: (context, index) => buildSuggestionCard(context, steps[index])
                )
            ),
          ],
        ),
      )
    );
  }

  Widget buildSuggestionCard(BuildContext context, OutingStepDto stepDto) {
    return Card(
      child: ListTile(
        leading: Text(
          stepDto.name,
        ),
        title: Image.network(stepDto.wherePoint),
        onTap: () {
          Get.defaultDialog(
            title: stepDto.name,
            content: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    stepDto.description
                  ),
                ),
                ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Add suggestion to backend
                      // This should pop the page and add the suggestion to the voting
                      // interface
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.how_to_vote
                    ),
                    label: const Text(
                      "Suggest",
                      style: TextStyle(
                        fontWeight: FontWeight.bold
                      ),
                    )
                )
              ],
            )
          );
        },
      ),
    );
  }
}
