import 'dart:async';

import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:flutter/material.dart';
import 'package:audiovision/Components/color.dart';
import 'package:audiovision/Onboboarding/onboarding_items.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final controller = OnboardingItems();
  final pageController = PageController();
  int currentPageIndex = 0;
  bool isLastPage = false;

  bool isSuccessTryMicrophone = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: isLastPage
            ? getStarted()
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //Skip Button
                  TextButton(
                      onPressed: () {
                        if (isSuccessTryMicrophone) {
                          pageController
                              .jumpToPage(controller.items.length - 1);
                        }
                        pageController.jumpToPage(2);
                      },
                      child: currentPageIndex != 2 || isSuccessTryMicrophone
                          ? const Text("Skip")
                          : Text("")),

                  //Indicator
                  SmoothPageIndicator(
                    controller: pageController,
                    count: controller.items.length,
                    onDotClicked: (index) => pageController.animateToPage(index,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeIn),
                    effect: const WormEffect(
                      dotHeight: 12,
                      dotWidth: 12,
                      activeDotColor: primaryColor,
                    ),
                  ),

                  //Next Button
                  TextButton(
                      onPressed: () {
                        pageController.nextPage(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeIn);
                      },
                      child: currentPageIndex != 2 || isSuccessTryMicrophone
                          ? const Text("Next")
                          : Text("")),
                ],
              ),
      ),
      body: GestureDetector(
        onDoubleTap: () {
          print(currentPageIndex);
          if (currentPageIndex == 2) {
            _listen();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: PageView.builder(
              onPageChanged: (index) => setState(() {
                    if (currentPageIndex != 2 || isSuccessTryMicrophone) {
                      // TextToSpeech.speak(
                      //     "You must try Double tap to activate voice command / microphone before continuing to the next page");
                      // return;
                    }
                    isLastPage = controller.items.length - 1 == index;
                    currentPageIndex = index;
                    print(currentPageIndex);
                  }),
              itemCount: controller.items.length,
              controller: pageController,
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(controller.items[index].image),
                    const SizedBox(height: 15),
                    Text(
                      controller.items[index].title,
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    Text(controller.items[index].descriptions,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 17),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    Text(controller.items[index].tag,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    _isListening
                        ? const Icon(
                            Icons.mic,
                            size: 50,
                            color: Colors.red,
                          )
                        : const SizedBox(),
                    const SizedBox(height: 10),
                    Text(
                      _text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }

  //Now the problem is when press get started button
  // after re run the app we see again the onboarding screen
  // so lets do one time onboarding

  //Get started button

  Widget getStarted() {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), color: primaryColor),
      width: MediaQuery.of(context).size.width * .9,
      height: 55,
      child: TextButton(
          onPressed: () async {
            final pres = await SharedPreferences.getInstance();
            pres.setBool("onboarding", true);

            //After we press get started button this onboarding value become true
            // same key
            if (!mounted) return;
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => MapPage()));
          },
          child: const Text(
            "Get started",
            style: TextStyle(color: Colors.white),
          )),
    );
  }

  bool _isListening = false;
  String _text = '';

  final stt.SpeechToText _speech = stt.SpeechToText();

  void _listen() async {
    print("object");
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
            isSuccessTryMicrophone = true;
            if (_text.contains("camera view")) {
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
