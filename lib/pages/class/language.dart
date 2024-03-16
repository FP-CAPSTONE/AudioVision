import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreferences {
  static Future<bool> isIndonesianSelected() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print("check language preference");
    print(prefs.getBool('isIndonesianSelected'));
    return prefs.getBool('isIndonesianSelected') ?? false;
  }

// get the device default language
  Locale getDefaultLocale() {
    return window.locale;
  }

// set application language when user open the application for the first time
  Future<void> setDefaultLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print("setDefaultLanguage");
    print(getDefaultLocale().languageCode);
    print(prefs.getBool('isIndonesianSelected'));
    // check if the the setting is exist
    if (prefs.getBool('isIndonesianSelected') == null) {
      //check the default device language
      if (getDefaultLocale().languageCode == "id") {
        print("set to id");
        prefs.setBool('isIndonesianSelected', true);
      } else {
        print("set to en");
        prefs.setBool('isIndonesianSelected', false);
      }
    }
  }
}
