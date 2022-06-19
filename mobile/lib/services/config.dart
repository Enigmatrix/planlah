import 'package:flutter/foundation.dart';

class Config {
  bool isDev() {
    return kDebugMode;
  }

  bool isProd() {
    return kReleaseMode;
  }
}