import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class ScanController extends GetxController {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  late CameraController cameraController;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    _checkDeviceOrientation();
    initCamera();
    initTFLite();
  }

  @override
  void onClose() {
    // Cancel the accelerometer subscription when the controller is closed
    _accelerometerSubscription?.cancel();
    isCameraInitialized(false);
    Get.delete<CameraController>();
  }

  @override
  void dispose() {
    // TODO : STOP CAMERA WHEN MOVING TO ANOTHER SCREEN
    // TODO: implement dispose
    super.dispose();
    cameraController.dispose();
  }

  FlutterVision vision = FlutterVision();

  late List<CameraDescription> cameras;
  var detectedObject = "".obs;
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

  // camera init to sending each frame to the model (set 10fps)
  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(cameras[0], ResolutionPreset.max);
      // await cameraController.initialize();
      await cameraController.initialize().then((value) {
        cameraController.startImageStream((image) {
          cameraCount++;
          // run object detection each 10 fps
          if (cameraCount % 10 == 0) {
            if (accelerometerEventY > 0) {
              cameraCount = 0;
              objectDetector(image);
            } else {
              Vibration.vibrate();
              cameraCount -= 1000;
              speak("tolong kamera lu yang benar lah wooooy!");
              print("tolong kamera lu yang benar lah wooooy!");
            }
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

  // load the model
  initTFLite() async {
    print("LOAD THE MODEL !");

    //flutter vision
    await vision.loadYoloModel(
      modelPath: 'assets/model/L_1kyv8n_float32.tflite',
      labels: 'assets/model/mylabels.txt',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
    print("MODEL LOAD SUCCESSFULLY");
  }

  // do the object detection each frame got from the camera
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
    if (result.isNotEmpty) {
      print("RESULTTTTTTTTTTTTTTTT:");
      print(result);

      detectionResult = result;
      print(result);
      //example result
      // [{box: [0.0, 763.1640625, 357.9225158691406, 1116.581787109375, 0.5627957582473755], tag: Stop}]

      speak(detectionResult[0]['tag']);
      Vibration.vibrate();

      // var box = detectionResult[0]['box'];
      // label = detectionResult[0]['tag'];
      // x = box[0];
      // y = box[1];
      // w = box[2] - x;
      // h = box[3] - y;
      // update();
    }
    // update();
  }
}
