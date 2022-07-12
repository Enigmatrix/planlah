import 'package:flutter/material.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/pages/profile_page_components/value_widget_builder.dart';

class UserProfileContent {
  static WidgetValueBuilder getUserProfileContentBuilder() {
    return (BuildContext context, UserSummaryDto user) {
      return CircleAvatar(
        backgroundImage: NetworkImage(user.imageLink),
      );
    };
  }
}


