import 'dart:async';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class ScanController extends GetxController {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  CameraController? cameraController;
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
    cameraController?.dispose();
    Get.delete<CameraController>();
  }

  @override
  void dispose() {
    // Cancel the accelerometer subscription when the controller is closed
    _accelerometerSubscription?.cancel();
    // Dispose of cameraController if it is not null
    cameraController?.dispose();
    Get.delete<CameraController>();
    super.dispose();
  }

  FlutterVision vision = FlutterVision();

  late List<CameraDescription> cameras;
  CameraImage? cameraImage;
  var detectedObject = "".obs;
  List<Map<String, dynamic>> detectionResult = [];
  bool canNotify = true;
  var accelerometerEventX, accelerometerEventY, accelerometerEventZ = 0.0;
  var cameraCount = 0;

  var isCameraInitialized = false.obs;

  // Check accelerometer data to determine device orientation
  void _checkDeviceOrientation() {
    bool canNotify = true; // Flag to control notification frequency

    // Store the subscription returned by accelerometerEvents.listen()
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      // print(event);
      // if the phone is not facing forward
      if (event.y < 0 && canNotify) {
        Vibration.vibrate();

        TextToSpeech.speak("Please hold your phone upright.");

        // Set canNotify to false to prevent further notifications
        canNotify = false;

        // Reset canNotify after a delay
        Future.delayed(Duration(seconds: 5), () {
          canNotify = true;
        });
      }
    });
  }

  // camera init to sending each frame to the model (set 10fps)
  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(cameras[0], ResolutionPreset.max,
          enableAudio: false);
      // await cameraController.initialize();
      await cameraController!.initialize().then((value) {
        detectionResult = [];
        cameraController!.startImageStream((image) {
          cameraCount++;
          print("cameraCountr" + cameraCount.toString());
          // run object detection each 10 fps
          // if (cameraCount % 10 == 0) {

          cameraImage = image;
          objectDetector(image);

          update();
          // }=
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission denied");
    }
  }

  // // load the model
  initTFLite() async {
    print("LOAD THE MODEL !");

    //flutter vision
    await vision.loadYoloModel(
      labels: 'assets/model/labels.txt',
      modelPath: 'assets/model/yolov8n_float32.tflite',
      // modelPath: 'assets/model/transfer-1.tflite',
      modelVersion: "yolov8",
      numThreads: 5,
      quantization: true,
      useGpu: false,
    );
    print("MODEL LOAD SUCCESSFULLY");
  }

  // do the object detection each frame got from the
  objectDetector(CameraImage image) async {
    // using flutter vision
    var result = await vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.5,
      confThreshold: 0.5,
      classThreshold: 0.6,
    );

    print("kont" + image.toString() + result.toString());
    if (result.isNotEmpty) {
      detectionResult = result;
      // print(result);
      //example result
      // [{box: [0.0, 763.1640625, 357.9225158691406, 1116.581787109375, 0.5627957582473755], tag: Stop}]

      if (canNotify) {
        Vibration.vibrate();
        print(detectionResult);
        TextToSpeech.speak(detectionResult[0]['tag']);

        // Set canNotify to false to prevent further notifications
        canNotify = false;

        // Reset canNotify after a delay
        Future.delayed(Duration(seconds: 5), () {
          canNotify = true;
        });
      }
    }
    update();
  }
}
