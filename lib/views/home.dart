import 'package:audiovision/mainAudio.dart';
import 'package:audiovision/screens/select_screen.dart';
import 'package:audiovision/views/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vibration/vibration.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  bool _isListening = false;
  String _text = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Appbar"),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Say:\n"
                "\"Go to Camera View\",\n"
                "\"Go to Map View\",\n"
                "\"Go to Audio Guide\",\n"
                "to navigate to another page",
                style: TextStyle(fontSize: 16),
              ),
              GestureDetector(
                onTap: () {
                  _isListening = false;
                  _text = "";
                  Vibration.vibrate();
                  // speak("say something");
                  // Get.to(CameraView());
                  _listen();
                },
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 50,
                  color: _isListening ? Colors.red : Colors.blue,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _text,
                style: TextStyle(fontSize: 16),
              ),
              // ElevatedButton(
              //   onPressed: () {
              //     Get.to(MyAudioGuide());
              //   },
              //   child: Container(
              //     child: Text('AudioGuide'),
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _text = "Listening...";
        });
        _speech.listen(onResult: (result) {
          setState(() {
            _text = result.recognizedWords.toLowerCase();
            print(_text);
            if (_text.contains("camera view")) {
              speak("navigate to CAMERA VIEW");
              Get.to(CameraView());
              _isListening = false;
              _text = "";
            } else if (_text.contains("map view")) {
              speak("navigate to MAP SCREEN");
              Get.to(SelectScreen());
              _isListening = false;
              _text = "";
            } else if (_text.contains("guide")) {
              speak("navigate to AUDIO GUIDE SCREEN");
              Get.to(MyAudioGuide());
              _isListening = false;
              _text = "";
            }
          });
        });
      } else {
        print('The user denied the use of speech recognition.');
      }
    }
  }
}
