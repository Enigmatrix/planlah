import 'package:flutter/material.dart';
import 'package:mobile/pages/profile_page_components/profile_skeleton.dart';
import 'package:mobile/widgets/profile_widget.dart';

import '../../dto/user.dart';

class ProfilePicture {

  static WidgetValueBuilder getUserProfilePictureBuilder() {
    return (BuildContext context, UserProfileDto user) {
      return ProfileWidget(imagePath: user.imageLink, onClicked: () {});
    };
  }

  static WidgetValueBuilder getOtherProfilePictureBuilder() {
    return (BuildContext context, UserProfileDto user) {
      return Center(
        child: buildImage(user),
      );
    };
  }

  static Widget buildImage(UserProfileDto user) {
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