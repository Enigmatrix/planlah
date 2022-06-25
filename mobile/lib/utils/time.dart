import 'package:intl/intl.dart';

class TimeUtil {
  static String now() {
    var now = DateTime.now();
    print(now.toString());
    // Could the flutter devs really not do this????????????
    return "${DateFormat("yyyy-MM-ddTHH:mm:ss").format(now)}Z";
  }

  // These functions assumes the string is sent from a DTO that has properly
  // formatted it

  static String formatForGroup(String string) {
    DateTime dt = DateTime.parse(string);
    DateTime now = DateTime.now();
    switch (dt.difference(now).inDays) {
      // Same day
      case 0:
        return "${dt.hour}:${dt.minute}";
      // Yesterday
      case -1:
        return "Yesterday";
      // Just return the month and day
      default:
        return "${dt.day} of ${dt.month}";
    }
  }

  static String formatForChatGroup(String string) {
    DateTime dt = DateTime.parse(string);
    return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute}";
  }
}