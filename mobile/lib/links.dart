import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/services/group.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart' show PlatformException;

Future<void> initUniLinks() async {
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    final initialLink = await getInitialUri();
    uriLinkStream.listen((link) async {
      if (link == null) return;
      await handleDeepLink(link);
      log("linkstream: $link");
    }).onError((e) {
      log("initUniLinks: err in listStream.listen callback: $e");
    });
    // Parse the link and warn the user, if it is not correct,
    // but keep in mind it could be `null`.
    if (initialLink == null) return;
    await handleDeepLink(initialLink);
  } on PlatformException catch (e) {
    log("initUniLinks: err in getInitialLink/listStream.listen: $e");
  }
}

handleDeepLink(Uri initialLink) async {
  switch (initialLink.host) {
    case "join": {
      if (initialLink.pathSegments.length != 1) return;
      final inviteId = initialLink.pathSegments[0];
      final groups = Get.find<GroupService>();
      final resp = await groups.joinByInvite(inviteId);
      // no context, so rely on Getx
      if (resp.isOk) {
        Get.snackbar(
          "Group",
          "You've added yourself to ${resp.body!.name}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
        );
      } else if (resp.unauthorized) {
        Get.snackbar(
          "ERR",
          "Login first!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
        );
      } else if (resp.hasError) {
        Get.snackbar(
          "ERR",
          resp.bodyString!,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
        );
      }
      break;
    }
  }
}
