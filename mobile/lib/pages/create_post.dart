import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/posts.dart';
import 'package:mobile/pages/take_picture_screen.dart';
import 'package:mobile/services/posts.dart';

class CreatePostPage extends StatefulWidget {
  int outingStepId;

  CreatePostPage({Key? key, required this.outingStepId}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {

  Uint8List? _imageBytes;
  TextEditingController titleController = TextEditingController();
  PostService postSvc = Get.find<PostService>();

  @override
  Widget build(BuildContext context) {
    // The single child scroll view is required to avoid overflow errors
    // when the image is uploaded.
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          buildTitleInputWidget(),
          buildImageWidget(),
          buildConfirmationWidget(),
        ],
      ),
    );
  }

  Widget buildTitleInputWidget() {
    return TextFormField(
        controller: titleController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Title",
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a title for your post";
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.always,
        maxLines: 1
    );
  }

  Widget buildImageWidget() {
    // Flexible is used because we cannot predict the size of the photo
    // uploaded/taken by the user.
    return Flexible(
      child: Column(
        children: [
          if (_imageBytes != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image(
                image: MemoryImage(_imageBytes!),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
                onPressed: obtainImage,
                icon: const Icon(Icons.image),
                label: _imageBytes == null ?  const Text("Choose Image") : const Text("Choose Another Image")
            ),
          ),
        ],
      ),
    );
  }

  Widget buildConfirmationWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextButton.icon(
            onPressed: () async {
              if (titleController.text == "") {
                return;
              }
              if (_imageBytes == null) {
                return;
              }
              final resp = await postSvc.create(CreatePostDto(
                  widget.outingStepId, titleController.text, _imageBytes!));
              if (resp.isOk) {
                showOkSnackbar("Post created!");
              } else {
                log(resp.bodyString!);
                showErrorSnackbar("Sorry, post could not be created :(");
              }
              // This is the preferred way to pop according to Flutter
              // https://dart-lang.github.io/linter/lints/use_build_context_synchronously.html
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(context).clearSnackBars();
              Navigator.of(context).pop();
            },
            icon: const Icon(
                Icons.check
            ),
            label: const Text("Okay")
        ),
      ],
    );
  }

  void obtainImage() async {
    String choice = await showDialog(context: context, builder: buildImageChoice);
    File file;
    if (choice == "Camera") {
      // Get the first camera
      final cameras = await availableCameras();
      final firstCamera = cameras.first;
      XFile imageFile = await Get.to(() => TakePictureScreen(camera: firstCamera));
      file = File(imageFile.path);
    } else {
      var result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result == null) {
        return;
      }

      file = File(result.files.single.path!);
    }
    if (file == null) return;

    setState(() {
      _imageBytes = file.readAsBytesSync();
    });
  }

  Widget buildImageChoice(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, "Camera");
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text("Take a picture"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, "File");
            },
            icon: const Icon(Icons.image),
            label: const Text("Upload image"),
          ),
        ],
      ),
    );
  }

  void showErrorSnackbar(String err) {
    SnackBar snackBar = SnackBar(
        content: Text(err),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1)
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showOkSnackbar(String msg) {
    SnackBar snackBar = SnackBar(
        content: Text(msg),
        duration: Duration(seconds: 1)
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

}
