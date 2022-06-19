import 'package:flutter/foundation.dart';

class Config {
  bool isDev() {
    return kDebugMode;
  }

  bool isProb() {
    return kReleaseMode;
  }
}