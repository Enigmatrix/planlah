import 'package:flutter/material.dart';
import 'package:mobile/pages/profile_page_components/profile_header.dart';
import 'package:mobile/pages/profile_page_components/value_widget_builder.dart';

import '../../dto/user.dart';

class OtherProfileHeader {
  static WidgetValueBuilder getOtherProfileHeaderBuilder() {
    return (BuildContext context, UserSummaryDto user) {
      return Column(
        children: <Widget>[
          ProfileHeaderWidget(userSummaryDto: user),
          IconButton(
            onPressed: () {
              // TODO: To redirect to the DM
            },
            icon: const Icon(Icons.mail)
          )
        ],
      );
    };
  }
}
