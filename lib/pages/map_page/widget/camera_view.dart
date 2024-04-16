import 'package:audiovision/controller/scan_controller.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class CameraView {
  Widget cameraView(context) {
    final Size size = MediaQuery.of(context).size;

    return SizedBox(
      height: 2000,
      width: 1500, // Example width of the camera view
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
                    ...displayBoxesAndPolygonsAroundRecognizedObjects(
                      size,
                      controller.detectionResult,
                      controller.cameraImage,
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                );
        },
      ),
    );
  }

  List<Widget> displayBoxesAndPolygonsAroundRecognizedObjects(
    Size screen,
    List<Map<String, dynamic>> detectionResult,
    cameraImage,
  ) {
    if (detectionResult.isEmpty) return []; // Ensure returning List<Widget>
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return detectionResult.map<Widget>((result) {
      // Specify return type as Widget
      // TextToSpeech.speak("${result['tag']}");
      print("resultttttttttttttttttts " + result.toString());

      List<Map<String, double>> polygons = (result['polygons'] as List?)
              ?.map<Map<String, double>>(
                  (item) => (item as Map?)?.cast<String, double>() ?? {})
              .toList() ??
          [];

      List<Offset> points = polygons
          .map((poly) => Offset(poly['x']! * factorX, poly['y']! * factorY))
          .toList();

      return Stack(
        children: [
          CustomPaint(
            painter: PolygonPainter(points, Colors.purple, 2.0),
          ),
          Positioned(
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
          ),
        ],
      );
    }).toList();
  }
}

class PolygonPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  PolygonPainter(this.points, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.lineTo(points[0].dx, points[0].dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
