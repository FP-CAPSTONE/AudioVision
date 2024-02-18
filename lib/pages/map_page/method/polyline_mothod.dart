import 'package:audiovision/pages/map_page/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineMethod {
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];

  void getPolyline() async {
    final String key = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      key,
      PointLatLng(
        MapPage.userLatitude,
        MapPage.userLongitude,
      ),
      PointLatLng(
        MapPage.destinationCoordinate.latitude,
        MapPage.destinationCoordinate.longitude,
      ),
      travelMode: TravelMode.walking,
    );
    // clear polyline first before update the polyline
    clearPolyline();
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    addPolyLine();
  }

  void addPolyLine() {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    MapPage.polylines[id] = polyline;
  }

  void clearPolyline() {
    polylineCoordinates.clear();
    MapPage.polylines.clear();
  }
}
