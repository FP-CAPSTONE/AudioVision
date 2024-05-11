import 'package:audiovision/direction_service.dart';
import 'package:audiovision/pages/map_page/map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:screen_brightness/screen_brightness.dart';

class NavigateMethod {
  void startNavigate(
    mapController,
    LatLng destination,
  ) {
    setBrightness(0);
    // resetBrightness();
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(MapPage.userLatitude, MapPage.userLongitude),
          zoom: 17,
          // bearing: _heading,
        ),
      ),
    );

    MapPage.isStartNavigate = true;
  }

  Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
    } catch (e) {
      print(e);
      throw 'Failed to set brightness';
    }
  }

  static Future<void> resetBrightness() async {
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      print(e);
      throw 'Failed to reset brightness';
    }
  }

  Future<Map<String, dynamic>> getDirection(
    LatLng userPosition,
    LatLng destination,
  ) async {
    String locale = MapPage.isIndonesianSelected ? "id" : "en";
    final String url_using_latlong =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${userPosition.latitude},${userPosition.longitude}&"
                "destination=${destination.latitude},${destination.longitude}&"
                "mode=walking&"
                "language=${locale}&"
                "key=" +
            dotenv.env['GOOGLE_MAPS_API_KEYS_AKHA'].toString(); //WARNINGG !!!

    var response = await http.get(Uri.parse(url_using_latlong));
    var json = convert.jsonDecode(response.body);
    Map<String, dynamic> results;
    List<dynamic> routes = json['routes'];
    if (routes.isNotEmpty) {
      results = {
        'bounds_ne': routes[0]['bounds']['northeast'],
        'bounds_sw': routes[0]['bounds']['southwest'],
        'start_location': routes[0]['legs'][0]['start_location'],
        'end_location': routes[0]['legs'][0]['end_location'],
        'polyline': routes[0]['overview_polyline']['points'],
        'polyline_decoded': PolylinePoints()
            .decodePolyline(routes[0]['overview_polyline']['points']),
      };

      List<dynamic> legs = routes[0]['legs'];
      if (legs.isNotEmpty) {
        List<dynamic> steps = legs[0]['steps'];
        List<Map<String, dynamic>> stepResults = [];
        for (var step in steps) {
          Map<String, dynamic> stepResult = {
            'distance': step['distance']['text'],
            'duration': step['duration']['text'],
            'end_lat': step['start_location']['lat'],
            'end_long': step['start_location']['lng'],
            'instructions':
                DirectionServcie().removeHtmlTags(step['html_instructions']),
          };

          if (step.containsKey('maneuver')) {
            stepResult['maneuver'] = step['maneuver'];
          }

          stepResults.add(stepResult);
        }

        results['steps'] = stepResults;
        MapPage.allSteps = results['steps'];
        MapPage.endLocation = results['end_location'];
      }
    } else {
      results = {
        'bounds_ne': 0,
        'bounds_sw': 0,
        'start_location': 0,
        'end_location': 0,
        'polyline': 0,
        'polyline_decoded': 0,
      };
    }
    return results;
  }

  static stopNavigate() {
    // find the north and south to animate the camera
    double minLat =
        MapPage.userLatitude < MapPage.destinationCoordinate.latitude
            ? MapPage.userLatitude
            : MapPage.destinationCoordinate.latitude;
    double minLng =
        MapPage.userLongitude < MapPage.destinationCoordinate.longitude
            ? MapPage.userLongitude
            : MapPage.destinationCoordinate.longitude;
    double maxLat =
        MapPage.userLatitude > MapPage.destinationCoordinate.latitude
            ? MapPage.userLatitude
            : MapPage.destinationCoordinate.latitude;
    double maxLng =
        MapPage.userLongitude > MapPage.destinationCoordinate.longitude
            ? MapPage.userLongitude
            : MapPage.destinationCoordinate.longitude;

    MapPage.mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // Padding
      ),
    );

    MapPage.isStartNavigate = false;
    resetBrightness();
  }

  int stepIndex = 0;
}
