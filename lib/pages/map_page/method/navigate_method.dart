import 'package:audiovision/direction_service.dart';
import 'package:audiovision/pages/map_page/map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class NavigateMethod {
  void startNavigate(
    mapController,
    LatLng destination,
  ) {
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
    getDirection(
      LatLng(
        MapPage.userLatitude,
        MapPage.userLongitude,
      ),
      LatLng(
        destination.latitude,
        destination.longitude,
      ),
    );
  }

  Future<Map<String, dynamic>> getDirection(
    LatLng userPosition,
    LatLng destination,
  ) async {
    final String urlUsingLatlong =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${userPosition.latitude},${userPosition.longitude}&"
        "destination=${destination.latitude},${destination.longitude}&"
        "mode=walking&"
        "key=AIzaSyCgjkSHUOL0bgO4w94tC4Z6je-7303-Jn4"; //WARNINGG !!!

    var response = await http.get(Uri.parse(urlUsingLatlong));
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
    }
    return results;
  }

  int stepIndex = 0;
}
