import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/pages/map_page/method/polyline_mothod.dart';
import 'package:audiovision/services/location_services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class LocationMethod {
  final Function? updateUI;
  final Function? updatePolylines;

  LocationMethod({
    this.updateUI,
    this.updatePolylines,
  });

  void listenToUserLocation(
    LocationService locationService,
  ) {
    // final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

    // always listen to the user position and update it
    locationService.locationStream.listen((userLocation) {
      MapPage.userLatitude = userLocation.latitude;
      MapPage.userLongitude = userLocation.longitude;

      updateUserMarkerPosition(
          LatLng(MapPage.userLatitude, MapPage.userLongitude));
      // Write user location data to the Firebase Realtime Database
      // databaseReference.child("users").child("user1").set({
      //   "latitude": userLocation.latitude,
      //   "longitude": userLocation.longitude,
      // }).then((_) {
      //   print("User location updated successfully");
      // }).catchError((error) {
      //   print("Failed to update user location: $error");
      // });
    });

    NavigateMethod().routeGuidance();
  }

  // update the user marker  position
  void updateUserMarkerPosition(
    LatLng newPosition,
  ) {
    MapPage.cameraPosition = CameraPosition(target: newPosition, zoom: 16.5);
    // Update marker for user's position or add it if not present
    MapPage.markers.removeWhere((marker) => marker.markerId.value == "You");
    MapPage.markers.add(
      Marker(
        markerId: const MarkerId("You"),
        position: newPosition,
      ),
    );
    updateUI!();

    if (MapPage.isStartNavigate) {
      PolylineMethod(updatePolylines!).getPolyline();
    }
  }
}
