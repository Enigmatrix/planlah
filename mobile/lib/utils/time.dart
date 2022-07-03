import 'package:intl/intl.dart';

class TimeUtil {
  static String now() {
    var now = DateTime.now();
    print(now.toString());
    // Could the flutter devs really not do this????????????
    return "${DateFormat("yyyy-MM-ddTHH:mm:ss").format(now)}Z";
  }

  /// Formats a DateTime.now() string into the format required for go
  static String formatForDto(String timeString) {
    // Format: 2022-06-26T16:14:17.325Z
    List<String> times = timeString.split(" ");
    if (times.isNotEmpty && times.length == 2) {
      String date = times.elementAt(0);
      String time = times.elementAt(1);
      return "${date}T${time}Z";
    } else {
      throw ArgumentError.value("TimeString is not correct format");
    }
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
        return "${dt.day}/${dt.month}";
    }
  }

  static String formatForChatGroup(String string) {
    DateTime dt = DateTime.parse(string);
    print("dt = ${dt.toString()}");
    return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute}";
  }
}