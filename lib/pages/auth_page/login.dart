import 'package:audiovision/pages/auth_page/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dummy_api.dart'; // tambahkan import untuk DummyApi

class LoginPage extends StatelessWidget {
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
              decoration: InputDecoration(labelText: 'Email'),
              onTap: () {
                _speak('Email field selected');
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              onTap: () {
                _speak('Password field selected');
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Login user
                String email = 'john.doe@example.com';
                String password = 'password123';
                bool loginResult = DummyApi.loginUser(email, password);
                if (loginResult) {
                  _speak('Login successful');
                } else {
                  _speak('Email or password is incorrect');
                }
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
