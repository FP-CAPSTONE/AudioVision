import 'dart:async';
<<<<<<< HEAD

=======
import 'package:audiovision/utils/text_to_speech.dart';
>>>>>>> map_guidance
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class ScanController extends GetxController {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  CameraController? cameraController;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
<<<<<<< HEAD
    _checkDeviceOrientation();
=======
    //_checkDeviceOrientation();
>>>>>>> map_guidance
    initCamera();
    initTFLite();
  }

  @override
  void onClose() {
    // Cancel the accelerometer subscription when the controller is closed
    _accelerometerSubscription?.cancel();
    cameraController?.dispose();
    Get.delete<CameraController>();
  }

  @override
  void dispose() {
    // TODO : STOP CAMERA WHEN MOVING TO ANOTHER SCREEN
    // TODO: implement dispose
    super.dispose();
    cameraController!.dispose();
  }

  FlutterVision vision = FlutterVision();

  late List<CameraDescription> cameras;
  CameraImage? cameraImage;
  var detectedObject = "".obs;
<<<<<<< HEAD
  List<Map<String, dynamic>> detectionResult = [
    {
      "box": [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
      ],
      "tag": ""
      // "polygons": List<Map<String, double>>: [{x:coordx, y:coordy}]
    }
  ];
=======
  List<Map<String, dynamic>> detectionResult = [];
  // List<Map<String, dynamic>> detectionResult = [
  //   {
  //     "box": [
  //       0.0,
  //       0.0,
  //       0.0,
  //       0.0,
  //       0.0,
  //     ],
  //     "tag": ""
  //     // "polygons": List<Map<String, double>>: [{x:coordx, y:coordy}]
  //   }
  // ];
>>>>>>> map_guidance
  var accelerometerEventX, accelerometerEventY, accelerometerEventZ = 0.0;
  var cameraCount = 0;

  // var x, y, w, h = 0.0;
  // var label = "";

  var isCameraInitialized = false.obs;

  final FlutterTts flutterTts = FlutterTts();

  // function text to speach
  Future<void> speak(String text) async {
    // await flutterTts.setLanguage("en-US");
    await flutterTts.setLanguage("id-ID"); // Set language to Indonesian
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  // Check accelerometer data to determine device orientation
<<<<<<< HEAD
  void _checkDeviceOrientation() {
    // Store the subscription returned by accelerometerEvents.listen()
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      print(event);
      accelerometerEventX = event.x;
      accelerometerEventY = event.y;
      accelerometerEventZ = event.z;
    });
  }
=======
  // void _checkDeviceOrientation() {
  //   // Store the subscription returned by accelerometerEvents.listen()
  //   _accelerometerSubscription =
  //       accelerometerEvents.listen((AccelerometerEvent event) {
  //     print(event);
  //     accelerometerEventX = event.x;
  //     accelerometerEventY = event.y;
  //     accelerometerEventZ = event.z;
  //   });
  // }
>>>>>>> map_guidance

  // camera init to sending each frame to the model (set 10fps)
  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(cameras[0], ResolutionPreset.max);
      // await cameraController.initialize();
      await cameraController!.initialize().then((value) {
<<<<<<< HEAD
=======
        detectionResult = [];
>>>>>>> map_guidance
        cameraController!.startImageStream((image) {
          cameraCount++;
          // run object detection each 10 fps
          if (cameraCount % 10 == 0) {
<<<<<<< HEAD
            if (accelerometerEventY > 0) {
              cameraCount = 0;
              objectDetector(image);
            } else {
              Vibration.vibrate();
              cameraCount -= 1000;
              speak("tolong kamera lu yang benar lah wooooy!");
              print("tolong kamera lu yang benar lah wooooy!");
            }
=======
            // if (accelerometerEventY > 0) {
            cameraImage = image;
            objectDetector(image);
            cameraCount = 0;
            // } else {
            //   Vibration.vibrate();
            //   cameraCount -= 1000;
            //   speak("tolong kamera lu yang benar lah wooooy!");
            //   print("tolong kamera lu yang benar lah wooooy!");
            // }
>>>>>>> map_guidance
          }
          update();
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission denied");
    }
  }

<<<<<<< HEAD
  // load the model
=======
  // // load the model
>>>>>>> map_guidance
  initTFLite() async {
    print("LOAD THE MODEL !");

    //flutter vision
    await vision.loadYoloModel(
<<<<<<< HEAD
      modelPath: 'assets/model/L_1kyv8n_float32.tflite',
      labels: 'assets/model/mylabels.txt',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 1,
      useGpu: false,
=======
      modelPath: 'assets/model/yolov5n.tflite',
      labels: 'assets/model/labels.txt',
      modelVersion: "yolov5",
      quantization: true,
      numThreads: 3,
      useGpu: true,
>>>>>>> map_guidance
    );
    //load yolo segmentation
    // await vision.loadYoloModel(
    //   modelPath: 'assets/model/mymodel_seg-n400.tflite',
    //   labels: 'assets/model/seg_label.txt',
    //   modelVersion: "yolov8seg",
    //   quantization: true,
    //   numThreads: 1,
    //   useGpu: false,
    // );
    print("MODEL LOAD SUCCESSFULLY");
  }

<<<<<<< HEAD
  // do the object detection each frame got from the camera
=======
  // do the object detection each frame got from the
>>>>>>> map_guidance
  objectDetector(CameraImage image) async {
    // using flutter vision
    var result = await vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );
    print(result);
    if (result.isNotEmpty) {
<<<<<<< HEAD
      print("RESULTTTTTTTTTTTTTTTT:");
      print(result);

=======
>>>>>>> map_guidance
      detectionResult = result;
      //example result
      // [{box: [0.0, 763.1640625, 357.9225158691406, 1116.581787109375, 0.5627957582473755], tag: Stop}]

      speak(detectionResult[0]['tag']);
      Vibration.vibrate();
<<<<<<< HEAD

      // var box = detectionResult[0]['box'];
      // label = detectionResult[0]['tag'];
      // x = box[0];
      // y = box[1];
      // w = box[2] - x;
      // h = box[3] - y;
      // update();
    }
    // update();
=======
    }
    // update();
  }

  List<Widget> displayBoxesAroundRecognizedObjects(
    Size screen,
  ) {
    if (detectionResult.isEmpty) return []; // Ensure returning List<Widget>
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);
    print(cameraImage?.height ?? 1);
    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return detectionResult.map((result) {
      // Specify return type as Widget
      TextToSpeech.speak("${result['tag']}");

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
>>>>>>> map_guidance
  }
}
