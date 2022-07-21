import 'dart:convert';
import 'dart:developer';

import 'package:mobile/services/base_connect.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SessionService extends BaseConnect {

  late Stream<dynamic> stream;

  Stream anyFriendRequest(int userId) {
    return stream.where((event) => event["kind"] == "friendRequest" && event["userId"] == userId);
  }

  Stream activeOuting(int groupId) {
    return stream.where((event) => event["kind"] == "activeOuting" && event["groupId"] == groupId);
  }

  Stream anyMessage() {
    return stream.where((event) => event["kind"] == "message");
  }

  Stream messagesForGroup(int groupId) {
    return stream.where((event) => event["kind"] == "message" && event["groupId"] == groupId);
  }

  Stream groups() {
    return stream.where((event) => event["kind"] == "groups");
  }

  void initConnection() {
    var uri = Uri.parse("ws://${BaseConnect.server}/session/updates");
    try {
      var channel = IOWebSocketChannel.connect(uri, headers: { "Authorization": "Bearer ${BaseConnect.token}" });
      stream = channel.stream.asBroadcastStream().map((str) => jsonDecode(str));
    }  on WebSocketChannelException catch (e) {
      log(e.toString());
    }
  }
}