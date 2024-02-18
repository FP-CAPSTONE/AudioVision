import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/pages/map_page/method/polyline_mothod.dart';
import 'package:audiovision/services/location_services.dart';
import 'package:audiovision/utils/map_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMethod {
  void listenToUserLocation(
    LocationService locationService,
  ) {
    int stepIndex = 0;
    // always listen to the user position and update it
    locationService.locationStream.listen((userLocation) async {
      // setState(() {
      MapPage.userLatitude = userLocation.latitude;
      MapPage.userLongitude = userLocation.longitude;
      updateUserMarkerPosition(
          LatLng(MapPage.userLatitude, MapPage.userLongitude));
      // });
      if (MapPage.isStartNavigate) {
        if (stepIndex < MapPage.allSteps.length) {
          double distanceToStep = await NavigateMethod().calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            MapPage.allSteps[stepIndex]['end_lat'],
            MapPage.allSteps[stepIndex]['end_long'],
          );

          double userAndDestinationDistance =
              await NavigateMethod().calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            MapPage.destinationCoordinate.latitude,
            MapPage.destinationCoordinate.longitude,
          );

          // Assuming there's a threshold distance to trigger the notification
          double thresholdDistance = 50; // meters
          print("WOYYYYYYYYYYYYYYYYYYYYYYYY");

          if (distanceToStep <= thresholdDistance &&
              userAndDestinationDistance > 10) {
            String maneuver = MapPage.allSteps[stepIndex]['maneuver'] ??
                'Continue'; // Default to 'Continue' if maneuver is not provided
            print("MASIHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH");
            print(maneuver);
            NavigateMethod().updateTextNavigate(maneuver);
            stepIndex++;
          }
          if (userAndDestinationDistance <= 10) {
            MapPage.isStartNavigate = false;
            print(
                "CONGRATULATIONSSSSSSSSSSSSSSSS YOU HAVE REACEHED THE DESTINATION");
            stepIndex = 0;
          }
        }
      }
    });
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

    if (MapPage.isStartNavigate) {
      // PolylineMethod().getPolyline();
    }
  }
}
