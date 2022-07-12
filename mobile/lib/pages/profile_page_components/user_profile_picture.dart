import 'package:flutter/material.dart';
import 'package:mobile/pages/profile_page_components/value_widget_builder.dart';
import 'package:mobile/widgets/profile_widget.dart';

import '../../dto/user.dart';

class UserProfilePicture {
  static WidgetValueBuilder getUserProfilePictureBuilder() {
    return (BuildContext context, UserSummaryDto user) {
      return ProfileWidget(imagePath: user.imageLink, onClicked: () {});
    };
  }
}
