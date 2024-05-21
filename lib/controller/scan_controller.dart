import 'dart:async';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:camera/camera.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class ScanController extends GetxController {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  CameraController? cameraController;
  double? screenWidth;

  ScanController(this.screenWidth);
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    gyroscope();
    initCamera();
    initModel();
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
  void gyroscope() {
    bool canNotify = true; // Flag to control notification frequency

    // Store the subscription returned by accelerometerEvents.listen()
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      notifyGyro(event);

      // print(event);
    });
  }

  void captureFrame() async {
    final XFile? image = await cameraController?.takePicture();
    // Process the captured image and upload it to Firebase
    uploadImageToFirebase(image!);
  }

  void uploadImageToFirebase(XFile imageFile) {
    final DatabaseReference databaseRef =
        FirebaseDatabase.instance.reference().child('camera_frames');
    databaseRef.push().set({
      'image_url': imageFile
          .path, // Example: Store image URL or base64 encoded image data
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  notifyGyro(event) {
    // if the phone is not facing forward
    if (event.y < 0 && canNotify) {
      Vibration.vibrate();

      TextToSpeech.speak("Please hold your phone upright.");

      // Set canNotify to false to prevent further notifications
      canNotify = false;

      // Reset canNotify after a delay
      Future.delayed(const Duration(seconds: 5), () {
        canNotify = true;
      });
    }
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
          // detect an object every 10 framse
          // if (cameraCount % 10 == 0) {
          cameraCount++;
          // print("cameraCountr$cameraCount");

          cameraImage = image;
          objectDetector(image);
          // }
          update();
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission denied");
    }
  }

  // // load the model
  initModel() async {
    print("LOAD THE MODEL !");

    await vision.loadYoloModel(
      labels: 'assets/model/labels.txt',
      modelPath: 'assets/model/yolov8n_float32.tflite',
      modelVersion: "yolov8",
      numThreads: 5,
      quantization: true,
      useGpu: false,
    );
    print("MODEL LOAD SUCCESSFULLY");
  }

// Define an array containing all dangerous object tags found on footpaths
  List<String> dangerousObjects = [
    'person',
    'bicycle',
    'car',
    'motorcycle',
    'bus',
    'truck',
    'traffic light',
    'fire hydrant',
    'stop sign',
    'parking meter',
    'bench',
    'chair',
    'refrigerator',
    'bed',
    'couch',
    'laptop'
  ];

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
    notifyUser(result);

    update();
  }

  notifyUser(var result) {
    // print("kont" + image.toString() + result.toString());
    if (result.isNotEmpty) {
      detectionResult = result;
      ObjectDetector.detectionResult = result;
      // print(result);
      //example result
      // [{box: [0.0, 763.1640625, 357.9225158691406, 1116.581787109375, 0.5627957582473755], tag: Stop}]

      for (var detectedObject in detectionResult) {
        var detectedTag = detectedObject['tag'];

        var box = detectedObject['box'];

        // Calculate the midpoint of the bounding box
        double x1 = box[0];
        double x2 = box[2];
        double midpoint = (x1 + x2) / 2;
        print("objectt1 $x1");
        print("objectt2 $x2");
        print("objectt3 $midpoint");

        // Determine the position relative to the screen width
        String position = (midpoint < screenWidth! / 2) ? 'left' : 'right';
        print("detected $position");

        if (canNotify && dangerousObjects.contains(detectedTag)) {
          // Trigger notification only if canNotify is true and the detected object is one of the dangerous objects
          Vibration.vibrate();
          print(detectionResult);

          //x1=  o = left
          //x1 =500 = right

          // TextToSpeech.speak(
          //     "Watch out! There is a $detectedTag on $position.");
          TextToSpeech.speak(
              "Watch out! there is A $detectedTag in front of you. ");

          // Set canNotify to false to prevent further notifications
          canNotify = false;

          // Reset canNotify after a delay
          Future.delayed(const Duration(seconds: 5), () {
            canNotify = true;
          });

          // Break the loop since we've already triggered the notification for one dangerous object
          break;
        }
      }
    }
  }
}

class ObjectDetector {
  static var detectionResult = [];

  checkInFront() {
    // print("kont" + image.toString() + detectionResult.toString());
    if (detectionResult.isNotEmpty) {
      for (var detectedObject in detectionResult) {
        var detectedTag = detectedObject['tag'];

        Vibration.vibrate();

        TextToSpeech.speak("there is A $detectedTag in front of you");
      }
    } else {
      TextToSpeech.speak("there is no object detected in front of you ");
    }
  }
}
