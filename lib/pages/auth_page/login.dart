import 'dart:math';

import 'package:audiovision/pages/auth_page/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dummy_api.dart'; // tambahkan import untuk DummyApi
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatelessWidget {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  void login(String email, password) async {
    try {
      print("login testt");
      var response = await http.post(
        Uri.parse("http://172.20.10.4:8000/auth/login"),
        body: jsonEncode({"email": email, "password": password}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      print(response);
      print(email);

      if (response.statusCode == 200) {
        _speak('Login successful');

        var data = jsonDecode(response.body.toString());
        print(data);

        var loginResult = data['loginResult'];
        var userId = loginResult['userId'];
        var name = loginResult['name'];
        var token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode({
          'token': token,
          'userId': userId,
          'userName': name,
          'userEmail': email,
        });

        prefs.setString('userData', userData);

        print("Account create successfuly");
      } else {
        _speak('Failed');
        print("Failed");
      }
    } catch (e) {
      print(e.toString());
    }
  }

  final FlutterTts flutterTts = FlutterTts();

  void _speak(String text) async {
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              onTap: () {
                _speak('Email field selected');
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              onTap: () {
                _speak('Password field selected');
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                login(_emailController.text.toString(),
                    _passwordController.text.toString());
              },
              child: Text('Login'),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text('Don\'t have an account? Click here to register.'),
            ),
          ],
        ),
      ),
    );
  }
}
