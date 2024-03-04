import 'package:audiovision/pages/register_page/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
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
