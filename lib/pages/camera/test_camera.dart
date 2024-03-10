import 'package:audiovision/controller/scan_controller.dart';
import 'package:audiovision/pages/map_page/widget/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:audiovision/pages/map_page/widget/camera_view.dart';

class TestCamera extends StatelessWidget {
  const TestCamera({Key? key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          title: Text("Camera View TEST"),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Get.back(); // Navigate back when the back button is pressed
              ScanController().onClose();
            },
          ),
        ),
        body: CameraView().cameraView(context));
  }
}
