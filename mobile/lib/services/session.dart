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

  Stream messageUpdate(int groupId) {
    return stream.where((event) => event["kind"] == "message" && event["groupId"] == groupId);
  }
  
  Stream groupUpdate(int groupId) {
    return stream.where((event) => event["kind"] == "group" && event["groupId"] == groupId);
  }

  Stream groups() {
    return stream.where((event) => event["kind"] == "groups");
  }

  void initConnection() {
    var uri = Uri.parse("ws://${BaseConnect.server}/session/updates");
    try {
      var channel = IOWebSocketChannel.connect(uri, headers: { "Authorization": "Bearer ${BaseConnect.token}" });
      stream = channel.stream.asBroadcastStream().map((str) => jsonDecode(str));
      log("websocket connection inited");
      stream.listen((event) {
        log(event.toString());
      }, onError: (e) {
        print(e.toString()); // consume the error somewhere, then broadcaster will shut up.
      });
    }  on WebSocketChannelException catch (e) {
      log(e.toString());
    }
  }
}