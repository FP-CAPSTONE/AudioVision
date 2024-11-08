import 'package:audiovision/pages/auth_page/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController =
      TextEditingController(text: "boben");
  // TextEditingController _emailController =
  //     TextEditingController(text: "abdul.saipi@student.president.ac.id");
  final TextEditingController _passwordController =
      TextEditingController(text: "passwordsaya");

  final FlutterTts flutterTts = FlutterTts();

  bool _isLoading = false;

  void _register() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    await AuthService.register(
      _nameController.text.toString(),
      _nameController.text.toString(),
      _passwordController.text.toString(),
      context,
    );

    setState(() {
      _isLoading = false; // Hide loading indicator
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Register',
                    style: TextStyle(fontSize: 24, color: Colors.black)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.black),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //   TextFormField(
                //     controller: _emailController,
                //     decoration: InputDecoration(
                //   labelText: 'Email',
                //   labelStyle: TextStyle(color: Colors.black),
                //   focusedBorder: OutlineInputBorder(
                //     borderSide: BorderSide(color: Colors.black),
                //   ),
                //   enabledBorder: OutlineInputBorder(
                //     borderSide: BorderSide(color: Colors.black),
                //   ),
                // ),
                //   ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.black),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black),
                  child: const Text('Register'),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Already have an account? Click here to Login.',
                    style: TextStyle(
                        color: Colors.black,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
