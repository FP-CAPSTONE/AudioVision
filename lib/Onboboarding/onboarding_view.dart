import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audiovision/Components/color.dart';
import 'package:audiovision/Onboboarding/onboarding_items.dart';
import 'package:audiovision/pages/map_page/map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:vibration/vibration.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({Key? key}) : super(key: key);

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final controller = OnboardingItems();
  final pageController = PageController();
  int currentPageIndex = 0;
  bool isLastPage = false;
  bool isSuccessTryMicrophone = false;
  bool _isListening = false;
  String _text = '';

  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: isLastPage ? _buildGetStartedButton() : _buildPageIndicator(),
      ),
      body: GestureDetector(
        onDoubleTap: () {
          if (currentPageIndex == 2) {
            _listen();
            TextToSpeech.speak("Audio command activated, say something");
          }
        },
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              child: PageView.builder(
                  onPageChanged: (index) {
                    setState(() {
                      currentPageIndex = index;
                      isLastPage = index == controller.items.length - 1;
                    });
                    _speakOnboardingText(index);
                  },
                  itemCount: controller.items.length,
                  controller: pageController,
                  itemBuilder: (context, index) {
                    return _buildPageContent(index);
                  }),
            ),
            Center(
              child: _isListening
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SizedBox(
                        //     height: MediaQuery.of(context).size.height *
                        //         0.), // Adjust the height as needed
                        const Icon(
                          Icons.mic,
                          size: 50,
                          color: Colors.red,
                        ),
                        SizedBox(
                            height:
                                10), // Add some spacing between the icon and text
                        Container(
                          decoration: BoxDecoration(
                            color: Colors
                                .grey, // Set your desired background color here
                            borderRadius: BorderRadius.circular(
                                8), // Optional: Add border radius to make it rounded
                          ),
                          padding: const EdgeInsets.all(
                              8), // Optional: Add padding around the text
                          child: Text(
                            _text,
                            style: const TextStyle(
                                fontSize: 16,
                                color:
                                    Colors.white), // Set text color if needed
                          ),
                        )
                      ],
                    )
                  : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            pageController.jumpToPage(2);
          },
          child: const Text("Skip"),
        ),
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
        TextButton(
          onPressed: () {
            pageController.nextPage(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeIn);
          },
          child: const Text("Next"),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return GestureDetector(
      onLongPress: () {
        TextToSpeech.speak("Get Started Button");
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: primaryColor,
        ),
        width: MediaQuery.of(context).size.width * 0.9,
        height: 55,
        child: TextButton(
          onPressed: () async {
            TextToSpeech.speak("Let's go");
            final prefs = await SharedPreferences.getInstance();
            prefs.setBool("onboarding", true);
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MapPage()),
            );
          },
          child: Text(
            "Get Started",
            style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width * 0.06),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    // Call startVibrationTimer when the index is 4 and the timer is not yet started
    if (index == 4) {
      Vibration.vibrate();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(controller.items[index].image),
        const SizedBox(height: 15),
        GestureDetector(
          onLongPress: () {
            if (index == 3) {
              TextToSpeech.speak(
                  "Nice. you have tried the voice reader. swipe to the right to continue");
              return;
            }
            TextToSpeech.speak(controller.items[index].title);
          },
          child: Text(
            controller.items[index].title,
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.07,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onLongPress: () {
            if (index == 3) {
              TextToSpeech.speak(
                  "Nice. you have tried the voice reader. swipe to the right to continue");
              return;
            }
            TextToSpeech.speak(controller.items[index].descriptions);
          },
          child: Text(
            controller.items[index].descriptions,
            style: TextStyle(
                color: Colors.grey,
                fontSize: MediaQuery.of(context).size.width * 0.04),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onLongPress: () {
            if (index == 3) {
              TextToSpeech.speak(
                  "Nice. you have tried the voice reader. swipe to the right to continue");
              return;
            }
            TextToSpeech.speak(controller.items[index].tag);
          },
          child: Text(
            controller.items[index].tag,
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _speakOnboardingText(int index) {
    switch (index) {
      case 0:
        TextToSpeech.speak(
            "Welcome To Audio Vision. We will help you and assist you to go to somewhere. Swipe to the right to continue");
        break;
      case 1:
        TextToSpeech.speak(
            "We developed a route guidance application with object detection to assist visually impaired people to travel. The object detection feature will help visualize the surroundings, and provide warnings through audio and vibration if there are dangerous objects. Don't worry, we'll be your eyes. Swipe to the right to continue");
        break;
      case 2:
        TextToSpeech.speak("Double tap to activate voice command /microphone");
        break;
      case 3:
        TextToSpeech.speak("Hold the screen to voice screen reader");
        break;
      case 4:
        TextToSpeech.speak(
            "If there are vibrations, it means there is a dangerous object. Be careful. swipe to the right to continue");
        break;
      case 5:
        TextToSpeech.speak(
            "- Say going, or go, or navigate to go to your destination \n"
            "- Say start navigate to start your route \n"
            "- Say stop navigate to stop your route \n"
            "- Say share location to share your location \n"
            "Swipe to the right to continue\n");
        break;
      case 6:
        TextToSpeech.speak(
            "Nice. you have finished the tutorial. Ready to go?. Let's make the first step with us. and go on a journey. Let's get started");
        break;
    }
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
            isSuccessTryMicrophone = true;
            if (_text.isNotEmpty &&
                !_text.contains("audio") &&
                !_text.contains("command")) {
              isSuccessTryMicrophone = true;
              TextToSpeech.speak(
                  "Nice, you have tried the voice command. swipe to continue");
            } else {
              _microphoneTimeout1();
            }
          });
        });
        _microphoneTimeout2();
      } else {
        print('The user denied the use of speech recognition.');
      }
    }
  }

  void _microphoneTimeout1() {
    Timer(const Duration(seconds: 12), () {
      setState(() {
        _isListening = false;
        _text = "";
      });
      print("Speech recognition timeout");
    });
  }

  void _microphoneTimeout2() {
    Timer(const Duration(seconds: 8), () {
      if (_text == "Listening...") {
        setState(() {
          _isListening = false;
          _text = "";
        });
        print("Speech recognition timeout");
      }
    });
  }
}
