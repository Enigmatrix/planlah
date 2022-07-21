import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:lit_relative_date_time/lit_relative_date_time.dart';

class TimeUtil {
  static String now() {
    var now = DateTime.now().add(const Duration(days: 365)).toLocal();
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

  static String formatForGroup(BuildContext context, String string) {
    DateTime dt = DateTime.parse(string);
    DateTime now = DateTime.now().toLocal();

    // If exactly the same day, just return the time
    // Else, return the relative datetime

    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return "${dt.hour}:${dt.minute}";
    } else {
      RelativeDateTime relativeDateTime = RelativeDateTime(dateTime: now, other: dt);
      RelativeDateFormat relativeDateFormat = RelativeDateFormat(Localizations.localeOf(context));
      return relativeDateFormat.format(relativeDateTime);
    }
  }

  static String formatDateTimeForSocialPost(DateTime dt) {
    return "${dt.day}/${dt.month} at ${dt.hour}:${dt.minute}";
  }

  static String formatForFrontend(String string) {
    final dt = DateTime.parse(string).toLocal();
    return DateFormat('yyyy-MM-dd - kk:mm').format(dt);
  }

  static DateTime parseFromDto(String? string) {
    if (string == null) {
      return DateTime.now();
    } else {
      return DateTime.parse(string).toLocal();
    }
  }

}