import 'dart:async';
import 'dart:ui' as ui;
import 'package:audiovision/pages/map_page/map.dart';
import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class MarkerMethod {
  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  static updateMarkerAndCameraRotation() {
    // Find the marker with markerId value "You" and update its rotation
    Iterable<Marker> markersToUpdate =
        MapPage.markers.where((marker) => marker.markerId.value == "You");

    List<Marker> updatedMarkers = [];

    for (var marker in markersToUpdate) {
      // Create a new marker with the updated rotation
      Marker updatedMarker = Marker(
        markerId: marker.markerId,
        position: marker.position,
        icon: marker.icon,
        infoWindow: marker.infoWindow,
        rotation: MapPage.compassHeading,
        anchor: marker.anchor,
      );
      updatedMarkers.add(updatedMarker);
    }

// Remove old markers and add updated markers
    MapPage.markers.removeWhere((marker) => marker.markerId.value == "You");
    MapPage.markers.addAll(updatedMarkers);

    // Perform the operation after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MapPage.mapController != null && MapPage.isStartNavigate) {
        // Access the mapController and perform operations
        MapPage.mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(MapPage.userLatitude, MapPage.userLongitude),
              zoom: 17, // Use the current zoom level
              bearing: MapPage
                  .compassHeading, // Rotate the camera based on the compass heading
            ),
          ),
        );
      } else {
        print("Map controller is null. Cannot animate camera.");
      }
    });
  }

  // this to ratate marker  according to the position direction
  // URL : https://stackoverflow.com/questions/56964500/flutter-google-maps-rotate-marker-according-to-the-driving-direction
  // static  double calculateBearing(LatLng startPoint, LatLng endPoint) {
  //   final double startLat = toRadians(startPoint.latitude);
  //   final double startLng = toRadians(startPoint.longitude);
  //   final double endLat = toRadians(endPoint.latitude);
  //   final double endLng = toRadians(endPoint.longitude);

  //   final double deltaLng = endLng - startLng;

  //   final double y = Math.sin(deltaLng) * Math.cos(endLat);
  //   final double x = Math.cos(startLat) * Math.sin(endLat) -
  //       Math.sin(startLat) * Math.cos(endLat) * Math.cos(deltaLng);

  //   final double bearing = Math.atan2(y, x);

  //   return (toDegrees(bearing) + 360) % 360;
  // }

  // double toRadians(double degrees) {
  //   return degrees * (Math.pi / 180.0);
  // }

  // double toDegrees(double radians) {
  //   return radians * (180.0 / Math.pi);
  // }
  // this to ratate marker  according to the position direction
  // rotation: calculateBearing(MapPage.userPreviousCoordinate,
  //         LatLng(MapPage.userLatitude, MapPage.userLongitude)) -
  //     90,
}
