import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/pages/map_page/method/polyline_mothod.dart';
import 'package:audiovision/services/location_services.dart';
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
    // always listen to the user position and update it
    locationService.locationStream.listen((userLocation) {
      MapPage.userLatitude = userLocation.latitude;
      MapPage.userLongitude = userLocation.longitude;
      updateUserMarkerPosition(
          LatLng(MapPage.userLatitude, MapPage.userLongitude));
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
