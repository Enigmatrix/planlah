import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/services/user.dart';

/// The base skeleton that the user profile page and the other user profile page
/// build upon.
///
///
///
/// This class will take in a
///   buildProfilePictureWidget (User vs other)
///   buildProfileHeaderWidget (User vs other)
///   buildProfileContentWidget (User vs other)
///
/// typedef Function(BuildContext context, UserSummaryDto user) => Widget

typedef WidgetValueBuilder = Widget Function(BuildContext context, UserSummaryDto user);

class ProfilePageSkeleton extends StatefulWidget {

  final UserSummaryDto user;
  final WidgetValueBuilder profilePictureWidgetBuilder;
  final WidgetValueBuilder profileHeaderWidgetBuilder;
  final WidgetValueBuilder profileContentWidgetBuilder;

  const ProfilePageSkeleton({
    Key? key,
    required this.user,
    required this.profilePictureWidgetBuilder,
    required this.profileHeaderWidgetBuilder,
    required this.profileContentWidgetBuilder,
  }) : super(key: key);

  @override
  State<ProfilePageSkeleton> createState() => _ProfilePageSkeletonState();
}

class _ProfilePageSkeletonState extends State<ProfilePageSkeleton> {

  final UserService userService = Get.find<UserService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

      ),
      body: Column(
        children: <Widget>[
          widget.profilePictureWidgetBuilder(context, widget.user),
          buildNameWidget(context),
          widget.profileHeaderWidgetBuilder(context, widget.user),
          widget.profileContentWidgetBuilder(context, widget.user),
        ],
      ),
    );
  }

  Widget buildNameWidget(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          widget.user.username,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold
          ),
        ),
        Text(
          widget.user.name
        )
      ],
    );
  }
}





























