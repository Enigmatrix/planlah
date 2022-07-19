import 'dart:io';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/pages/group_chat_page.dart';

import 'package:mobile/services/group.dart';
import 'package:mobile/utils/errors.dart';

import '../dto/user.dart';


class CreateGroupPage extends StatefulWidget {
  UserSummaryDto userSummaryDto;

  CreateGroupPage({
    Key? key,
    required this.userSummaryDto
  }) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {

  final groupService = Get.find<GroupService>();

  String createGroupName = "";
  String createGroupDescription = "";
  final _groupNameKey = GlobalKey<FormFieldState>();
  final _groupDescKey = GlobalKey<FormFieldState>();

  Uint8List _imageBytes = Uint8List(0);

  Size size = const Size(1, 1);

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create a new group",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Image.asset(
              "assets/create_group.png"
              // "assets/undraw_Lives_matter_38lv.png"
            ),
            buildCreateGroupNameTextBox(),
            buildCreateGroupDescTextBox(),
            buildUserImagePicker(),
            buildCreateGroupConfirmationButton()
          ],
        ),
      ),
    );
  }

  void createGroup() async {
    var response = await groupService.createGroup(CreateGroupDto(createGroupName, createGroupDescription, _imageBytes));
    if (response.isOk) {
      GroupSummaryDto group = response.body!;
      Get.off(() => GroupChatPage(chatGroup: group, userSummaryDto: widget.userSummaryDto));
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, response);
    }
  }

  final textPadding = const EdgeInsets.only(
    left: 20.0,
    right: 20.0,
    top: 5.0,
    bottom: 5.0,
  );

  Widget buildCreateGroupNameTextBox() {
    return Padding(
      padding: textPadding,
      child: TextFormField(
        key: _groupNameKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Group Name",
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a name for your group";
          }
          return null;
        },
        onChanged: (value) {
          setState(
                  () {
                createGroupName = value;
              }
          );
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  Widget buildCreateGroupDescTextBox() {
    return Padding(
      padding: textPadding,
      child: TextFormField(
        key: _groupDescKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Group Description",
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a description for your group";
          }
          return null;
        },
        onChanged: (value) {
          setState(
                  () {
                createGroupDescription = value;
              }
          );
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  Widget buildCreateGroupConfirmationButton() {
    return ElevatedButton.icon(
        onPressed: () {
          if (_groupNameKey.currentState!.validate() && _groupDescKey.currentState!.validate() && _imageBytes != Uint8List(0)) {
            createGroup();
          }
        },
        icon: const Icon(
          Icons.group_add,
        ),
        label: const Text(
          "Create"
        )
    );
  }

  Widget buildUserImagePicker() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black, spreadRadius: 1)],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: MemoryImage(_imageBytes),
              radius: size.width * 0.25,
            ),
          ),
        ),
        ElevatedButton.icon(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(type: FileType.image);

              if (result == null) return;

              final file = File(result.files.single.path!);
              setState(() {
                _imageBytes = file.readAsBytesSync();
              });
            },
            icon: const Icon(
              Icons.file_upload
            ),
            label: const Text(
              "Upload a picture"
            )
        ),
      ],
    );
  }

}
