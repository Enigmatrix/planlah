import 'package:flutter/material.dart';
import 'package:mobile/pages/profile_page_components/profile_header.dart';
import 'package:mobile/pages/profile_page_components/value_widget_builder.dart';

import '../../dto/user.dart';

class UserProfileHeader {
  static WidgetValueBuilder getUserProfileHeaderBuilder() {
    return (BuildContext context, UserSummaryDto user) {
      return ProfileHeaderWidget(userSummaryDto: user);
    };
  }
}
