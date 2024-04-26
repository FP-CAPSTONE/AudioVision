import 'package:audiovision/pages/map_page/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolylineMethod {
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];
  final Function callback;

  PolylineMethod(this.callback);

  void getPolyline(LatLng firstCoordinate, LatLng secondCoordinate) async {
    final String key = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      key,
      PointLatLng(
        firstCoordinate.latitude,
        firstCoordinate.longitude,
      ),
      PointLatLng(
        secondCoordinate.latitude,
        secondCoordinate.longitude,
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
    print(polylineCoordinates.toString());
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Color.fromARGB(255, 73, 73, 73),
      points: polylineCoordinates,
      width: 5,
      jointType: JointType.bevel,
      patterns: <PatternItem>[
        PatternItem.dot, // 10 pixels dashed line
        PatternItem.gap(50), // 5 pixels gap
      ],
      zIndex: 2,
      startCap: Cap.buttCap,
      endCap: Cap.squareCap,
    );
    callback(polyline);
  }

  void clearPolyline() {
    polylineCoordinates.clear();
    MapPage.polylines.clear();
  }
}
