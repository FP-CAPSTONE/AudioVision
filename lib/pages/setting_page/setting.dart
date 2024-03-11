import 'package:audiovision/pages/home_page/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      HomeScreen.isIndonesianSelected =
          prefs.getBool('isIndonesianSelected') ?? false;
    });
  }

  Future<void> _saveLanguage(bool isIndonesianSelected) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isIndonesianSelected', isIndonesianSelected);
  }

  @override
  Widget build(BuildContext context) {
    String titleText = HomeScreen.isIndonesianSelected
        ? 'Pengaturan Bahasa'
        : 'Language Settings';
    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        leading: IconButton(
            onPressed: () {
              Get.to(
                () => HomeScreen(),
              );
            },
            icon: Icon(
              Icons.arrow_back,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Select Language:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            SwitchListTile(
              title: Text('Bahasa Indonesia'),
              value: HomeScreen.isIndonesianSelected,
              onChanged: (value) {
                setState(() {
                  HomeScreen.isIndonesianSelected = value;
                });
                _saveLanguage(value);
              },
            ),
            SizedBox(height: 10),
            SwitchListTile(
              title: Text('English'),
              value: !HomeScreen.isIndonesianSelected,
              onChanged: (value) {
                setState(() {
                  HomeScreen.isIndonesianSelected = !value;
                });
                _saveLanguage(!value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
