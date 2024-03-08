import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class RegisterPage extends StatelessWidget {
  final FlutterTts flutterTts = FlutterTts();

  RegisterPage({super.key});

  void _speak(String text) async {
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Register', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Register'),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Text('Already have an account? Click here to login..'),
            ),
          ],
        ),
      ),
    );
  }
}
