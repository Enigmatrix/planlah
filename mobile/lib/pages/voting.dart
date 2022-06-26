import 'package:flutter/material.dart';
import 'package:mobile/main.dart';

import 'package:reorderables/reorderables.dart';


class VotingPage extends StatefulWidget {
  const VotingPage({Key? key}) : super(key: key);

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Voting",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Text(
              "Here are the best locations for you and your friends",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold
              ),
            ),
          ),

          // Hardcoded for now
        ],
      ),
    );
  }

  Widget buildVotingCard(BuildContext context) {
    return Card(

    );
  }
}
