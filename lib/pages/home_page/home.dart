// ignore_for_file: avoid_print

import 'dart:async';

import 'package:audiovision/mainAudio.dart';
import 'package:audiovision/pages/auth_page/services/auth_services.dart';
import 'package:audiovision/pages/camera/camera.dart';
import 'package:audiovision/pages/camera/test_camera.dart';
import 'package:audiovision/pages/class/language.dart';
import 'package:audiovision/pages/auth_page/login.dart';
import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/widget/camera_view.dart';
import 'package:audiovision/pages/setting_page/setting.dart';
import 'package:audiovision/screens/select_screen.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vibration/vibration.dart';

class HomeScreen extends StatefulWidget {
  static bool isIndonesianSelected = true;
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _title = '';

  bool _isListening = false;
  String _text = '';
  Future<void> _loadTitle() async {
    // user open the app for the first time set the default language setting
    await LanguagePreferences().setDefaultLanguage();

    // set the value of language
    HomeScreen.isIndonesianSelected =
        await LanguagePreferences.isIndonesianSelected();
    setState(() {
      _title = HomeScreen.isIndonesianSelected ? 'Selamat Datang' : 'Welcome';
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadTitle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        _isListening = false;
        _text = '';
        Vibration.vibrate();
        _listen();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Container(),
          actions: [
            IconButton(
                onPressed: () {
                  Get.to(
                    () => SettingPage(),
                  );
                },
                icon: Icon(Icons.settings))
          ],
          title: Text(_title),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Get.to(() => LoginPage());
                },
                child: HomeScreen.isIndonesianSelected
                    ? Text("PERGI KE LOGIN")
                    : Text("GO TO LOGIN"),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.to(const TestCamera());
                },
                child: Text("GO TO TEST CAMERA"),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.to(const YoloVideo());
                },
                child: Text("GO TO CAMERA"),
              ),
              ElevatedButton(
                onPressed: () {
                  AuthService.logOut();
                },
                child: Text("Log Out"),
              ),
              SizedBox(
                height: 100,
              ),
              GestureDetector(
                onTap: () {
                  Get.to(() => const MapPage());
                },
                child: const Text(
                  "DOULBE TAP ANYWHERE ON THE SCREEN\n"
                  "\n"
                  "and Say:\n"
                  "\"Go to Camera View\",\n"
                  "\"Go to Map Screen\",\n"
                  "\"Go to Audio Guide\",\n"
                  "\"Go to Map View\",\n"
                  "to navigate to another page",
                  style: TextStyle(fontSize: 16),
                ),
              ),
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
          print("Listening...");
        });

        _speech.listen(onResult: (result) {
          setState(() {
            _text = result.recognizedWords.toLowerCase();
            print(_text);
            if (_text.contains("camera view")) {
              TextToSpeech.speak("navigate to CAMERA VIEW");
              _isListening = false;
              _text = "";
              Get.to(const TestCamera());
            } else if (_text.contains("map screen")) {
              TextToSpeech.speak("navigate to MAP SCREEN");
              Get.to(const SelectScreen());
              _isListening = false;
              _text = "";
            } else if (_text.contains("guide")) {
              TextToSpeech.speak("navigate to AUDIO GUIDE SCREEN");
              Get.to(MyAudioGuide());
              _isListening = false;
              _text = "";
            } else if (_text.contains("map view")) {
              TextToSpeech.speak("navigate toMAP VIEW SCREEN");
              Get.to(const MapPage());
              _isListening = false;
              _text = "";
            } else {
              // stop listening
              _microphoneTimeout1();
            }
          });
        });
        // stop listening
        _microphoneTimeout2();
      } else {
        print('The user denied the use of speech recognition.');
      }
    }
  }

  // stop listening after 8 seconds
  void _microphoneTimeout1() {
    Timer(const Duration(seconds: 8), () {
      // Reset _isListening 8 seconds
      setState(() {
        _isListening = false;
        _text = ""; // Clear the recognized text
      });
      print("Speech recognition timeout");
    });
  }

  // stop listening if the user did not say anything
  void _microphoneTimeout2() {
    Timer(const Duration(seconds: 5), () {
      if (_text == "Listening...") {
        // Reset _isListening if no speech is recognized after 5 seconds
        setState(() {
          _isListening = false;
          _text = ""; // Clear the recognized text
        });
        print("Speech recognition timeout");
      }
    });
  }
}



// UTILS

              //  MICROPHONE ICON TO ACTIVATE THE MICROPHONE
              // GestureDetector(
              //   onTap: () {
              //     _isListening = false;
              //     _text = "";
              //     Vibration.vibrate();
              //     // TextToSpeech.speak("say something");
              //     // Get.to(CameraView());
              //     _listen();
              //   },
              //   child: Icon(
              //     _isListening ? Icons.mic : Icons.mic_none,
              //     size: 50,
              //     color: _isListening ? Colors.red : Colors.blue,
              //   ),
              // ),