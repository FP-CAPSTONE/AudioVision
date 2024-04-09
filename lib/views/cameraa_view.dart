import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraaView extends StatefulWidget {
  const CameraaView({Key? key}) : super(key: key);

  @override
  _CameraaViewState createState() => _CameraaViewState();
}

class _CameraaViewState extends State<CameraaView> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Get the list of available cameras and set the first camera as the default one
    availableCameras().then((cameras) {
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras[0], ResolutionPreset.medium);
        _initializeControllerFuture = _controller.initialize();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Page'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller); // Display the camera preview
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
