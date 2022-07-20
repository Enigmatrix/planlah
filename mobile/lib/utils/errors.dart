import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ErrorManager {
  static Future<void> showErrorMessage(BuildContext context, String msg) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.red[500]!,
      content: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.grey[200]!,),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(msg, style: TextStyle(color: Colors.grey[300]!), maxLines: 2,),
          ),
        ],
      ),
    ));
  }

  static Future<void> showError(BuildContext context, Response response) async {
    final err = jsonDecode(response.bodyString!);
    var msg = "";
    switch(err["kind"]) {
      case "FRIENDLY_ERROR":
        msg = err["message"];
        break;
      default:
        msg = "An unexpected error occurred";
    }

    log(response.bodyString!);

    await showErrorMessage(context, msg);
  }
}