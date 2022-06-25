import 'package:intl/intl.dart';

class TimeUtil {
  static String now() {
    var now = DateTime.now();
    print(now.toString());
    // Could the flutter devs really not do this????????????
    return "${DateFormat("yyyy-MM-ddTHH:mm:ss").format(now)}Z";
  }
}