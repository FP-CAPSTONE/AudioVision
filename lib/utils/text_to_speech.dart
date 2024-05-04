import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:audiovision/pages/map_page/map.dart';

class TextToSpeech {
  static final FlutterTts _flutterTts = FlutterTts();

  static Future<void> speak(String text) async {
    String language = MapPage.isIndonesianSelected ? "id" : "en";

    // Translate the text if the selected language is Indonesian
    if (language == "id") {
      text = await translateText(text, "en", "id");
    }

    await _flutterTts.setLanguage(language);
    await _flutterTts.setPitch(1);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  // Function to translate text using the translator package
  static Future<String> translateText(
      String text, String from, String to) async {
    final translator = GoogleTranslator();

    Translation translation =
        await translator.translate(text, from: from, to: to);

    return translation.text;
  }
}
