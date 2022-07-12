import 'package:flutter/material.dart';
import 'package:mobile/pages/profile_page_components/value_widget_builder.dart';

import '../../dto/user.dart';

class OtherProfilePicture {
  static WidgetValueBuilder getOtherProfilePictureBuilder() {
    return (BuildContext context, UserSummaryDto user) {
      return Center(
        child: buildImage(user),
      );
    };
  }

  static Widget buildImage(UserSummaryDto user) {
    final image = NetworkImage(user.imageLink);

    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: Ink.image(
          image: image,
          fit: BoxFit.cover,
          width: 128,
          height: 128,
        ),
      ),
    );
  }
}