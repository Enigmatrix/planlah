import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile/utils/errors.dart';
import 'package:mobile/widgets/wait_widget.dart';

class TakePictureScreen extends StatefulWidget {

  final CameraDescription camera;

  const TakePictureScreen({
    Key? key,
    required this.camera
  }) : super(key: key);

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return waitWidget();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            if (!mounted) {
              return;
            }

            // Once the picture is taken, return the image directly
            Navigator.pop(context, image);
          } catch (e) {
            ErrorManager.showErrorMessage(context, e.toString());
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
