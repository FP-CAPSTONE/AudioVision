import 'package:audiovision/pages/auth_page/login.dart';
import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static String? userName;
  // static String? userEmail;
  static String? userId;

  static bool isAuthenticate = false;

  // Function to check authentication status
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if 'userData' key exists in preferences
    if (!prefs.containsKey('userData')) {
      print("no user data in pref");
      return false;
    }

    // Retrieve token from preferences
    final userDataString = prefs.getString('userData');
    print("userdata$userDataString");
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      final token = userData['token'];
      userName = userData['userName'];
      userId = userData['userId'].toString();
      print("userToken $token");
      // userEmail = userData['userEmail'].toString();

      isAuthenticate = token != null;

      return token !=
          null; // Return true if token is not null, indicating user is logged in
    } else {
      return false; // Return false if userDataString is null
    }
  }

  static String apiUrl = "https://audiovision-413417.as.r.appspot.com/";
  static login(String email, password, BuildContext context) async {
    try {
      print("login testt$email");
      var response = await http.post(
        Uri.parse("${apiUrl}auth/login"),
        body: jsonEncode({"email": "$email@example.com", "password": password}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        TextToSpeech.speak('Login successful');

        var data = jsonDecode(response.body.toString());
        var loginResult = data['loginResult'];
        var userId = loginResult['userId'];
        var name = loginResult['name'];
        var token = loginResult['token'];

        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode({
          'token': token,
          'userId': userId,
          'userName': name,
          'userEmail': email,
        });

        print("userData $userData");

        prefs.setString('userData', userData);

        isAuthenticated();

        Get.to(const MapPage());
        print("Login successfuly");
      } else {
        TextToSpeech.speak('Login Failed, incorrect username or passwrod ');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Login Failed, incorrect username or passwrod'),
          ),
        );
        print("Failed");
      }
    } catch (e) {
      print(e.toString());
    }
  }

  static register(String name, email, password, BuildContext context) async {
    try {
      var response = await http.post(
        Uri.parse("${apiUrl}auth/register"),
        body: jsonEncode({
          "name": name,
          "email": email + "@example.com",
          "password": password,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        TextToSpeech.speak('Register successful');

        var data = jsonDecode(response.body.toString());
        print(data);

        var loginResult = data['user'];
        var userId = loginResult['uid'];
        var name = loginResult['displayName'];
        var token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode({
          'token': token,
          'userId': userId,
          'userName': name,
          'userEmail': email,
        });

        prefs.setString('userData', userData);

        isAuthenticated();

        TextToSpeech.speak('Registration Success, Account create successfuly');
        Get.to(const MapPage());
      } else {
        TextToSpeech.speak(
            'Registration Failed, username is taken. try to use another username ');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'Registration Failed, username is taken. try to use another username'),
          ),
        );
      }
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<void> logOut() async {
    final pref = await SharedPreferences.getInstance();

    Get.to(const LoginPage());
    await pref.clear();
  }
}
