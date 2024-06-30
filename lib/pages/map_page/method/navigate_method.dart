import 'package:audiovision/direction_service.dart';
import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/share_location_method.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:screen_brightness/screen_brightness.dart';

class NavigateMethod {
  void startNavigate(
    mapController,
    LatLng destination,
  ) {
    MapPage.canNotify = false;
    Future.delayed(const Duration(seconds: 2), () {
      MapPage.canNotify = true;
    });
    setBrightness(0.1);
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
    Future.delayed(const Duration(seconds: 5), () {
      getNearLocationAddress();
    });

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
    final String urlUsingLatlong =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${userPosition.latitude},${userPosition.longitude}&destination=${destination.latitude},${destination.longitude}&mode=walking&language=$locale&key=${dotenv.env['GOOGLE_MAPS_API_KEYS_AKHA']}"; //WARNINGG !!!

    var response = await http.get(Uri.parse(urlUsingLatlong));
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
      print("routes $routes[0]");

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

  // Function to calculate total distance and total duration
  Map<String, dynamic> calculateTotals(List<dynamic> steps) {
    double totalDistance = 0.0;
    int totalDuration = 0;
    print("object");

    for (var step in steps) {
      print("object $step");
      // Extract the distance value and unit from step['distance']
      List<String> distanceParts = step['distance'].split(' ');
      String distanceString = distanceParts[0].toString();
      double distanceValue = double.parse(distanceString.replaceAll(',', '.'));
      String distanceUnit = distanceParts[1];

      // Convert distance to kilometers if it's in meters
      if (distanceUnit == 'm') {
        distanceValue /= 1000; // Convert meters to kilometers
      }

      // Add the converted distance to the total distance
      totalDistance += distanceValue;

      // Add the duration to the total duration
      totalDuration += int.parse(step['duration'].split(' ')[0]);
    }

    // Update total duration outside the loop
    MapPage.totalDurationToDestination = totalDuration;

    MapPage.total_distance = totalDistance;
    MapPage.total_duration = totalDuration;

    return {'totalDistance': totalDistance, 'totalDuration': totalDuration};
  }

  getNearLocationAddress() async {
    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS_AKHA'].toString();
    // String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString(); // udah gabisa
    GooglePlace googlePlace = GooglePlace(apiKey);

    var result = await googlePlace.search
        .getNearBySearch(
          Location(lat: MapPage.userLatitude, lng: MapPage.userLongitude),
          30,
          language: MapPage.isIndonesianSelected ? "id" : "en",
        )
        .timeout(const Duration(seconds: 50)); // Increase timeout duration

    if (result != null) {
      print("near loca ${result.results![1].name}");
      MapPage.nearLocationAddress = result.results![1].name!;
    }
    print("near location add ${MapPage.nearLocationAddress}");
  }

  int stepIndex = 0;
}
