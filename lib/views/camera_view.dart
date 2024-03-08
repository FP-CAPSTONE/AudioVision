import 'package:audiovision/controller/scan_controller.dart';
import 'package:audiovision/widget/object_detected.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';

class CameraView extends StatelessWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera View"),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                      // Draw black mask
                      painter:
                          MaskPainter(MediaQuery.of(context).size.height * 0.5),
                    ),

                    CustomPaint(
                      // Use CustomPaint to draw the bounding box
                      painter: BoundingBoxPainter(
                          controller.detectionResult, context),
                    ),
                    DetectedObjectWidget(controller
                        .detectionResult), // Display detected object info
                    const Text("data"),
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

// Custom Painter to draw black mask
class MaskPainter extends CustomPainter {
  final double maskHeight;

  MaskPainter(this.maskHeight);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.black.withOpacity(0.5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, maskHeight), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
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
