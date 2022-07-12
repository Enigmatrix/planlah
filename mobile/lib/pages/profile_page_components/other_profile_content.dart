import 'package:flutter/material.dart';
import 'package:mobile/pages/profile_page_components/value_widget_builder.dart';

import '../../dto/user.dart';

class OtherProfileContent {
  static WidgetValueBuilder getOtherProfileContentBuilder() {
    return (BuildContext context, UserSummaryDto user) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user.imageLink),
      );
    };
  }
}
