// ignore_for_file: non_constant_identifier_names

import 'dart:convert' as convert;
// import 'package:flutter/services.dart';
import 'package:audiovision/views/map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class DirectionServcie {
  final String region = 'ID';
  final String language = 'id';
  final String travelMode = 'walking';

  // Text-to-Speech config
  final String ttsLanguage = 'id';
  FlutterTts flutterTts = FlutterTts();
  // maps config
  final String key = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
  DirectionServcie() {
    // Initialize FlutterTts with the specified language
    flutterTts.setLanguage(ttsLanguage);
  }

  Future<String> getPlaceId(String input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key';

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var placeId = json['candidates'][0]['place_id'] as String;

    print(placeId);
    return placeId;
  }

  Future<Map<String, dynamic>> getPlace(String input) async {
    final placeId = await getPlaceId(input);

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key';

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);
    var results = json['result'] as Map<String, dynamic>;

    print(results);
    return results;
  }

  FlutterTts flutterTtsLanguage = FlutterTts();

  Future speak(String text) async {
    await flutterTtsLanguage.speak(text);
  }

  String removeHtmlTags(String htmlText) {
    var document = parse(htmlText);
    return parse(document.body!.text).documentElement!.text;
  }

  // TODO: buat fungsi current user location, return ke var origin

  Future<Map<String, dynamic>> getDirections(
      String origin, String destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&region=$region&language=$language&mode=$travelMode&key=$key';

    var response = await http.get(Uri.parse(url));
    var json = convert.jsonDecode(response.body);

    List<dynamic> routes = json['routes'];
    Map<String, dynamic> results = {
      'bounds_ne': routes[0]['bounds']['northeast'],
      'bounds_sw': routes[0]['bounds']['southwest'],
      'start_location': routes[0]['legs'][0]['start_location'],
      'end_location': routes[0]['legs'][0]['end_location'],
      'polyline': routes[0]['overview_polyline']['points'],
      'polyline_decoded': PolylinePoints()
          .decodePolyline(routes[0]['overview_polyline']['points']),
    };

    if (routes.isNotEmpty) {
      List<dynamic> legs = routes[0]['legs'];
      if (legs.isNotEmpty) {
        List<dynamic> steps = legs[0]['steps'];
        List<Map<String, dynamic>> stepResults = [];

        for (var step in steps) {
          Map<String, dynamic> stepResult = {
            'distance': step['distance']['text'],
            'duration': step['duration']['text'],
            'instructions': removeHtmlTags(step['html_instructions']),
          };
          if (step.containsKey('maneuver')) {
            stepResult['maneuver'] = step['maneuver'];
          }

          stepResults.add(stepResult);
        }

        results['steps'] = stepResults;
      }
    }

    print('Bounds NE: ${results['bounds_ne']}');
    print('Bounds SW: ${results['bounds_sw']}');
    print('Start Location: ${results['start_location']}');
    print('End Location: ${results['end_location']}');
    print('Polyline: ${results['polyline']}');
    print('Polyline Decoded: ${results['polyline_decoded']}');
    print('Steps:');

    for (var step in results['steps']) {
      print(step);
      String textToSpeak =
          'Jarak: ${step['distance']}, Durasi: ${step['duration']}, Instruksi: ${step['instructions']}';
      if (step.containsKey('maneuver')) {
        textToSpeak += ', Manuver: ${step['maneuver']}';
      }
      // await speak(textToSpeak);
      // await Future.delayed(Duration(seconds: 3));
      await speakWithCompletion(textToSpeak);
    }

    return results;
  }

// get direction using user current location lat long and destination lat and long;
  Future<Map<String, dynamic>> get_direction(
    LatLng user_position,
    LatLng destination,
  ) async {
    bool isNavigate = true;
    final String url_using_latlong =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${user_position.latitude},${user_position.longitude}&"
        "destination=${destination.latitude},${destination.longitude}&"
        "mode=walking&"
        "key=$key";

    var response = await http.get(Uri.parse(url_using_latlong));
    var json = convert.jsonDecode(response.body);

    List<dynamic> routes = json['routes'];
    Map<String, dynamic> results = {
      'bounds_ne': routes[0]['bounds']['northeast'],
      'bounds_sw': routes[0]['bounds']['southwest'],
      'start_location': routes[0]['legs'][0]['start_location'],
      'end_location': routes[0]['legs'][0]['end_location'],
      'polyline': routes[0]['overview_polyline']['points'],
      'polyline_decoded': PolylinePoints()
          .decodePolyline(routes[0]['overview_polyline']['points']),
    };

    if (routes.isNotEmpty) {
      List<dynamic> legs = routes[0]['legs'];
      if (legs.isNotEmpty) {
        List<dynamic> steps = legs[0]['steps'];
        List<Map<String, dynamic>> stepResults = [];
        for (var step in steps) {
          Map<String, dynamic> stepResult = {
            'distance': step['distance']['text'],
            'duration': step['duration']['text'],
            'instructions': removeHtmlTags(step['html_instructions']),
          };

          if (step.containsKey('maneuver')) {
            stepResult['maneuver'] = step['maneuver'];
          }

          stepResults.add(stepResult);
        }

        results['steps'] = stepResults;
      }
    }

    print('Bounds NE: ${results['bounds_ne']}');
    print('Bounds SW: ${results['bounds_sw']}');
    print('Start Location: ${results['start_location']}');
    print('End Location: ${results['end_location']}');
    print('Polyline: ${results['polyline']}');
    print('Polyline Decoded: ${results['polyline_decoded']}');
    print('Steps:');
    // while (isNavigate) {
    for (var step in results['steps']) {
      print(MapPage.userLatitude);
      print(step);
      String textToSpeak =
          'Jarak: ${step['distance']}, Durasi: ${step['duration']}, Instruksi: ${step['instructions']}';
      if (step.containsKey('maneuver')) {
        textToSpeak += ', Manuver: ${step['maneuver']}';
      }
      // await speak(textToSpeak);
      // await Future.delayed(Duration(seconds: 3));
      // await speakWithCompletion(textToSpeak);
    }
    // }

    return results;
  }

  Future<void> speakWithCompletion(String text) async {
    await flutterTts.speak(text);
    await flutterTts.awaitSpeakCompletion(
        true); // Wait for the completion of the current speak operation
    await Future.delayed(Duration(seconds: 3)); // Add a delay if needed
  }
}
