import 'package:flutter/material.dart';

Widget waitWidget() {
  return Center(
    child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(),
          ),
        ]),
  );
}