import 'package:audiovision/pages/auth_page/register.dart';
import 'package:audiovision/pages/auth_page/services/auth_services.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _emailController =
      TextEditingController(text: "kminchelle");
  TextEditingController _passwordController =
      TextEditingController(text: "0lelplR");

  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    await AuthService.login(
        _emailController.text.toString(), _passwordController.text.toString());

    setState(() {
      _isLoading = false; // Hide loading indicator
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Login', style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                onTap: () {
                  TextToSpeech.speak('Email field selected');
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onTap: () {
                  TextToSpeech.speak('Password field selected');
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _login, // Disable button if isLoading is true
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
