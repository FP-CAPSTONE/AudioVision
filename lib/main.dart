import 'package:audiovision/Onboboarding/onboarding_view.dart';
import 'package:audiovision/firebase_options.dart';
import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Load .env file
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final onboarding = prefs.getBool("onboarding") ?? false;

  runApp(MyApp(onboarding: onboarding));
}

class MyApp extends StatelessWidget {
  final bool onboarding;
  const MyApp({super.key, this.onboarding = false});

  @override
  Widget build(BuildContext context) {
    TextToSpeech.speak(
        "Welcome To Audio Vision. We will help you and assist you to go to somewhere.");
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AudioVision',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.black, primary: Colors.black
        ),
      ),
      home: onboarding ? MapPage() : OnboardingView()
    );
  }
}
