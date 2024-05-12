import 'package:audiovision/pages/map_page/map.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isIndonesianSelected = false;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isIndonesianSelected = prefs.getBool('isIndonesianSelected') ?? false;
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    });
  }

  Future<void> _saveSetting() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isIndonesianSelected', _isIndonesianSelected);
    await prefs.setDouble('fontSize', _fontSize);
  }

  @override
  Widget build(BuildContext context) {
    String titleText = _isIndonesianSelected ? 'Pengaturan' : 'Settings';
    String fontSizeTitle =
        _isIndonesianSelected ? 'Pilih Besar Huruf' : 'Select Font Size';
    return Scaffold(
      appBar: AppBar(
        title: Text(titleText,
            style: TextStyle(fontSize: _fontSize * 1.3 ?? 16.0)),
        leading: IconButton(
          onPressed: () {
            Get.to(() => const MapPage());
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Select Language:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Bahasa Indonesia'),
                value: _isIndonesianSelected,
                onChanged: (value) {
                  setState(() {
                    _isIndonesianSelected = value;
                  });
                  _saveSetting();
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('English'),
                value: !_isIndonesianSelected,
                onChanged: (value) {
                  setState(() {
                    _isIndonesianSelected = !value;
                  });
                  _saveSetting();
                },
              ),
              const SizedBox(height: 20),
              Text(
                fontSizeTitle,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile(
                    title: Text(_isIndonesianSelected ? 'Kecil' : 'Small'),
                    value: 12.0,
                    groupValue: _fontSize,
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value ?? 12.0;
                      });
                      _saveSetting();
                    },
                  ),
                  RadioListTile(
                    title: Text(_isIndonesianSelected ? 'Sedang' : 'Medium'),
                    value: 18.0,
                    groupValue: _fontSize,
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value ?? 18.0;
                      });
                      _saveSetting();
                    },
                  ),
                  RadioListTile(
                    title: Text(_isIndonesianSelected ? 'Besar' : 'Large'),
                    value: 24.0,
                    groupValue: _fontSize,
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value ?? 24.0;
                      });
                      _saveSetting();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Slider(
                value: _fontSize ?? 16.0,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                },
                onChangeEnd: (value) {
                  _saveSetting();
                },
              ),
              const SizedBox(height: 20),
              Text(
                _isIndonesianSelected ? 'Pratinjau Teks' : 'Preview Text',
                style: TextStyle(fontSize: _fontSize ?? 16.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
