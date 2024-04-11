import 'package:audiovision/controller/scan_controller.dart';
<<<<<<< HEAD
=======
import 'package:audiovision/pages/map_page/widget/camera_view.dart';
import 'package:audiovision/utils/text_to_speech.dart';
>>>>>>> map_guidance
import 'package:audiovision/widget/object_detected.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
// import 'package:audiovision/pages/map_page/widget/camera_view.dart';

class CameraViewv extends StatelessWidget {
  const CameraViewv({Key? key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(
        title: Text("Camera View"),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.back(); // Navigate back when the back button is pressed
            ScanController().onClose();
          },
        ),
      ),
      body: GetBuilder<ScanController>(
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
                    Text("data"),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                );
        },
      ),
    );
  }
=======
        appBar: AppBar(
          title: Text("Camera View"),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Get.back(); // Navigate back when the back button is pressed
              ScanController().onClose();
            },
          ),
        ),
        body: CameraView().cameraView(context)
>>>>>>> map_guidance

        // GetBuilder<ScanController>(
        //   init: ScanController(),
        //   builder: (controller) {
        //     return controller.isCameraInitialized.value
        //         ? Stack(
        //             fit: StackFit.expand,
        //             children: [
        //               // CameraPreview(controller.cameraController!),
        //               // ...ScanController().displayBoxesAroundRecognizedObjects(
        //               //   size,
        //               // ),
        //               // CustomPaint(
        //               //   // Use CustomPaint to draw the bounding box
        //               //   painter: BoundingBoxPainter(
        //               //       controller.detectionResult, context),
        //               // ),
        //               // DetectedObjectWidget(
        //               //   controller.detectionResult,
        //               // ),
        //               SizedBox(
        //                 height: 200,
        //               ), // Display detected object info
        //               // Center(child: Text("data")),
        //             ],
        //           )
        //         : const Center(
        //             child: CircularProgressIndicator(),
        //           );
        //   },
        // ),
        );
  }
}



// WIDGET FIR BUILD OBJECT
// Widget _buildDetectedObject(List<Map<String, dynamic>> detectionResult) {
//   if (detectionResult.isEmpty || detectionResult[0] == null) {
//     // Return an empty container or some placeholder widget if detectionResult is empty or its first element is null
//     return Container();
//   }

//   // Extracting box coordinates
//   List<double> box = detectionResult[0]['box'].cast<double>();
//   double x1 = box[0];
//   double y1 = box[1];
//   double x2 = box[2];
//   double y2 = box[3];
//   double confidence = box[4];

//   // Extracting tag
//   String tag = detectionResult[0]['tag'];
//   String tag_confidence =
//       '$tag - Confidence: ${confidence.toStringAsFixed(2)}'; // Format confidence as a string

//   return Center(
//     child: Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.6),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         tag_confidence,
//         style: TextStyle(color: Colors.white),
//       ),
//     ),
//   );
// }
