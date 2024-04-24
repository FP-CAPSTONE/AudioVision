import 'onboarding_info.dart';

class OnboardingItems {
  List<OnboardingInfo> items = [
    OnboardingInfo(
        title: "Welcome To Audio Vision",
        descriptions: "We will help you and assist you to go to somewhere.",
        tag: " ",
        image: "assets/image/boardinglogos.jpg"),
    OnboardingInfo(
        title: "Audio Vision",
        descriptions:
            "We developed a route guidance application with object detection to assist visually impaired people to travel. The object detection feature will help visualize the surroundings, and provide warnings through audio and vibration if there are dangerous objects.",
        tag: "Don't worry, we'll be your eyes",
        image: "assets/image/blind.png"),
    OnboardingInfo(
        title: "User Guide",
        descriptions: "Double tap to activate voice command /microphone",
        tag: "Try It!",
        image: "assets/image/doubleTap1.gif"),
    OnboardingInfo(
        title: "User Guide",
        descriptions: "Hold the screen to voice screen reader",
        tag: "Try It!",
        image: "assets/image/holdTap.gif"),
    OnboardingInfo(
        title: "User Guide",
        descriptions:
            "If there are vibrations, it means there is a  dangerous object. Becarefull",
        tag: " ",
        image: "assets/image/vibration1.gif"),
    OnboardingInfo(
        title: "Ready to go?",
        descriptions: "Let's make the first step with us and go on a journey",
        tag: "Let's Get Started",
        image: "assets/image/boardinglogos.jpg"),
  ];
}
