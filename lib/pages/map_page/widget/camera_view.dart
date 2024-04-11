import 'package:audiovision/controller/scan_controller.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:audiovision/widget/object_detected.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class CameraView {
  Widget cameraView(context) {
    final Size size = MediaQuery.of(context).size;

    return SizedBox(
      height: 200,
      width: 150, // Example width of the camera view
      child: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          return controller.isCameraInitialized.value
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    AspectRatio(
                      aspectRatio:
                          controller.cameraController!.value.aspectRatio,
                      child: CameraPreview(controller.cameraController!),
                    ),

                    // ...ScanController().displayBoxesAroundRecognizedObjects(
                    //   size,
                    // ),
                    ...displayBoxesAroundRecognizedObjects(
                      size,
                      controller.detectionResult,
                      controller.cameraImage,
                    )
                    // CustomPaint(
                    //   // Use CustomPaint to draw the bounding box
                    //   painter: BoundingBoxPainter(
                    //       controller.detectionResult, context),
                    // ),
                    // DetectedObjectWidget(controller
                    //     .detectionResult), // Display detected object info
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                );
        },
      ),
    );
  }

  List<Widget> displayBoxesAroundRecognizedObjects(
    Size screen,
    detectionResult,
    cameraImage,
  ) {
    if (detectionResult.isEmpty) return []; // Ensure returning List<Widget>
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return detectionResult.map<Widget>((result) {
      // Specify return type as Widget
      TextToSpeech.speak("${result['tag']}");
      print(result);
      print("resultttttttttttttttttt");
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
