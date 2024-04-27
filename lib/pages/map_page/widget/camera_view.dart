import 'package:audiovision/controller/scan_controller.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class CameraView {
  Map<String, Color> classColorMap = {
    'person': Colors.blue,
    'bicycle': Colors.red,
    'car': Colors.green,
    'motorcycle': Colors.orange,
    'airplane': Colors.yellow,
    'bus': Colors.purple,
    'train': Colors.teal,
    'truck': Colors.deepOrange,
    'boat': Colors.indigo,
    'traffic light': Colors.amber,
    'fire hydrant': Colors.brown,
    'stop sign': Colors.redAccent,
    'parking meter': Colors.lightBlue,
    'bench': Colors.lime,
    'bird': Colors.cyan,
    'cat': Colors.pink,
    'dog': Colors.deepPurple,
    'horse': Colors.blueGrey,
    'sheep': Colors.deepOrangeAccent,
    'cow': Colors.lightGreen,
    'elephant': Colors.purpleAccent,
    'bear': Colors.deepPurpleAccent,
    'zebra': Colors.yellowAccent,
    'giraffe': Colors.limeAccent,
    'backpack': Colors.tealAccent,
    'umbrella': Colors.blueAccent,
    'handbag': Colors.redAccent,
    'tie': Colors.greenAccent,
    'suitcase': Colors.deepOrangeAccent,
    'frisbee': Colors.amberAccent,
    'skis': Colors.indigoAccent,
    'snowboard': Colors.blueAccent,
    'sports ball': Colors.redAccent,
    'kite': Colors.orangeAccent,
    'baseball bat': Colors.yellowAccent,
    'baseball glove': Colors.limeAccent,
    'skateboard': Colors.deepOrangeAccent,
    'surfboard': Colors.indigoAccent,
    'tennis racket': Colors.blueAccent,
    'bottle': Colors.greenAccent,
    'wine glass': Colors.pinkAccent,
    'cup': Colors.tealAccent,
    'fork': Colors.amberAccent,
    'knife': Colors.deepOrangeAccent,
    'spoon': Colors.lightGreenAccent,
    'bowl': Colors.deepPurpleAccent,
    'banana': Colors.yellowAccent,
    'apple': Colors.lightGreenAccent,
    'sandwich': Colors.redAccent,
    'orange': Colors.orangeAccent,
    'broccoli': Colors.greenAccent,
    'carrot': Colors.deepOrangeAccent,
    'hot dog': Colors.redAccent,
    'pizza': Colors.orangeAccent,
    'donut': Colors.pinkAccent,
    'cake': Colors.purpleAccent,
    'chair': Colors.tealAccent,
    'couch': Colors.deepOrangeAccent,
    'potted plant': Colors.greenAccent,
    'bed': Colors.blueAccent,
    'dining table': Colors.redAccent,
    'toilet': Colors.yellowAccent,
    'tv': Colors.redAccent,
    'laptop': Colors.blueAccent,
    'mouse': Colors.grey,
    'remote': Colors.indigoAccent,
    'keyboard': Colors.orangeAccent,
    'cell phone': Colors.greenAccent,
    'microwave': Colors.redAccent,
    'oven': Colors.orangeAccent,
    'toaster': Colors.yellowAccent,
    'sink': Colors.blueAccent,
    'refrigerator': Colors.lightGreenAccent,
    'book': Colors.deepPurpleAccent,
    'clock': Colors.orangeAccent,
    'vase': Colors.yellowAccent,
    'scissors': Colors.redAccent,
    'teddy bear': Colors.pinkAccent,
    'hair drier': Colors.indigoAccent,
    'toothbrush': Colors.blueAccent,
  };

  Widget cameraView(context) {
    final Size size = MediaQuery.of(context).size;

    return SizedBox(
      height: 200,
      width: 150, // Example width of the camera view
      child: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          return controller.isCameraInitialized.value
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate the aspect ratio of the camera view
                    double aspectRatio =
                        constraints.maxWidth / constraints.maxHeight;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        AspectRatio(
                          aspectRatio: aspectRatio,
                          child: CameraPreview(controller.cameraController!),
                        ),
                        ...displayBoxesAndPolygonsAroundRecognizedObjects(
                          Size(
                              constraints.maxWidth,
                              constraints
                                  .maxHeight), // Pass the size to your display function
                          controller.detectionResult,
                          controller.cameraImage,
                        ),
                      ],
                    );
                  },
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
            return Stack(
        children: [
          
          Positioned(
            left: result["box"][0] * factorX,
            top: result["box"][1] * factorY,
            width: (result["box"][2] - result["box"][0]) * factorX,
            height: (result["box"][3] - result["box"][1]) * factorY,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                border: Border.all(
                  color: classColorMap[result['tag']] ??
                      Colors.grey, // Use pink as default if no color is found
                  width: 2.0,
                ),
              ),
              child: Text(
                "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  background: Paint()
                    ..color = classColorMap[result['tag']] ??
                        Colors.grey, // Use grey as default if no color is found
                  color: Colors.white,
                  fontSize: 10.0,
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


// Specify return type as Widget
      // TextToSpeech.speak("${result['tag']}");
      

      // List<Map<String, double>> polygons = (result['polygons'] as List?)
      //         ?.map<Map<String, double>>(
      //             (item) => (item as Map?)?.cast<String, double>() ?? {})
      //         .toList() ??
      //     [];

      // List<Offset> points = polygons
      //     .map((poly) => Offset(poly['x']! * factorX, poly['y']! * factorY))
      //     .toList();

// CustomPaint(
          //   painter: PolygonPainter(points, Colors.purple, 2.0),
          // ),
