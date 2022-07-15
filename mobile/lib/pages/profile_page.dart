import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/pages/profile_page_components/profile_content_components.dart';
import 'package:mobile/pages/profile_page_components/profile_header.dart';
import 'package:mobile/pages/profile_page_components/profile_picture.dart';
import 'package:mobile/pages/profile_page_components/profile_skeleton.dart';
import 'package:mobile/services/user.dart';

import '../widgets/wait_widget.dart';

class ProfilePage extends StatefulWidget {

  final int userId;

  const ProfilePage({
    Key? key,
    required this.userId
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final userService = Get.find<UserService>();
  late WidgetValueBuilder profilePictureWidgetBuilder;
  late WidgetValueBuilder profileHeaderWidgetBuilder;
  late WidgetValueBuilder profileContentWidgetBuilder;

  @override
  void initState() {
    super.initState();
    initializeWidgetBuilders(context);
  }

  Future<Response<UserSummaryDto?>> getUserInfo() async {
    if (widget.userId == -1) {
      return await userService.getInfo();
    } else {
      return await userService.getUserInfo(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getUserInfo(),
        builder: (BuildContext context, AsyncSnapshot<Response<UserSummaryDto?>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isOk) {
              return ProfilePageSkeleton(
                user: snapshot.data!.body!,
                profilePictureWidgetBuilder: profilePictureWidgetBuilder,
                profileContentWidgetBuilder: profileContentWidgetBuilder,
                profileHeaderWidgetBuilder: profileHeaderWidgetBuilder,
              );
            } else {
              return buildErrorPage(context);
            }
          } else {
            return waitWidget();
          }
        }
    );
  }

  Widget buildErrorPage(BuildContext context) {
    return const Center(
      child: Text(
        "We encountered an issue loading the user profile! Please refresh the page",
        style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  /// Initialize the widget builders based on whether it should be the
  /// user or the other user.
  void initializeWidgetBuilders(BuildContext context) {
    // -1 denotes it being the user's own profile
    if (widget.userId == -1) {
      profilePictureWidgetBuilder = ProfilePicture.getUserProfilePictureBuilder();
      profileHeaderWidgetBuilder = ProfileHeader.getUserProfileHeaderBuilder();
      profileContentWidgetBuilder = ProfileContent.getProfileContentBuilder();
    } else {
      profilePictureWidgetBuilder = ProfilePicture.getOtherProfilePictureBuilder();
      profileHeaderWidgetBuilder = ProfileHeader.getOtherProfileHeaderBuilder();
      profileContentWidgetBuilder = ProfileContent.getProfileContentBuilder();
    }
  }
}
