import 'package:audiovision/controller/scan_controller.dart';
import 'package:audiovision/widget/object_detected.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class CameraView {
  Widget cameraView(context) {
    return SizedBox(
      height: 200,
      width: 150, // Example width of the camera view
      child: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          return controller.isCameraInitialized.value
              ? Stack(
                  children: [
                    CameraPreview(controller.cameraController!),
                    CustomPaint(
                      // Use CustomPaint to draw the bounding box
                      painter: BoundingBoxPainter(
                          controller.detectionResult, context),
                    ),
                    DetectedObjectWidget(controller
                        .detectionResult), // Display detected object info
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                );
        },
      ),
    );
  }
}
