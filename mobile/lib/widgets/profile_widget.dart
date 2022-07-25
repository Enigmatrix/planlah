import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/services/user.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/utils/errors.dart';

/// Utility widget for displaying the profile picture.

class ProfileWidget extends StatefulWidget {
  final String imagePath;
  final VoidCallback onClicked;

  const ProfileWidget({
    Key? key,
    required this.imagePath,
    required this.onClicked,
  }): super(key: key);

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {

  late String imagePath;

  @override
  void initState() {
    super.initState();
    imagePath = widget.imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          buildImage(),
          Positioned(
            bottom: 0,
            right: 4,
            child: buildEditIcon(AppTheme.accentColor),
          ),
        ],
      )
    );
  }

  Widget buildImage() {
    final image = NetworkImage(imagePath);

    return ClipOval(
      child: Material(
        color: Colors.transparent,
        child: Ink.image(
            image: image,
            fit: BoxFit.cover,
            width: 128,
            height: 128,
            child: InkWell(
              onTap: widget.onClicked,
            ),
        ),
      ),
    );
  }

  Widget buildEditIcon(Color color) => buildCircle(
    color: Colors.white,
    all: 3,
    child: buildCircle(
      color: color,
      all: 8,
      child: InkWell(
        onTap: () async {
          final result = await FilePicker.platform.pickFiles(type: FileType.image);

          if (result == null) return;

          final file = File(result.files.single.path!);
          final imageBytes = file.readAsBytesSync();

          final userSvc = Get.find<UserService>();
          final resp = await userSvc.editImage(imageBytes);
          if (resp.isOk) {
            final resp = await userSvc.getInfo();
            if (resp.isOk) {
              setState(() {
                imagePath = resp.body!.imageLink;
              });
            } else {
              if (!mounted) return;
              await ErrorManager.showError(context, resp);
            }
          } else {
            if (!mounted) return;
            await ErrorManager.showError(context, resp);
          }
        },
        child: const Icon(
            Icons.edit,
            color: Colors.white,
          size: 20
        ),
      )
    )
  );

  Widget buildCircle({
    required Widget child,
    required double all,
    required Color color,
  }) =>
      ClipOval(
        child: Container(
          padding: EdgeInsets.all(all),
          color: color,
          child: child,
  ));
}