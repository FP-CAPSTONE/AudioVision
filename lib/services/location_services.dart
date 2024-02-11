import 'dart:async';

import 'package:audiovision/services/user_location.dart';
import 'package:location/location.dart';

class LocationService {
  Location location = Location();
  final StreamController<UserLocation> _locationStreamController =
      StreamController<UserLocation>.broadcast();
  Stream<UserLocation> get locationStream => _locationStreamController.stream;

  LocationService() {
    location.requestPermission().then((permissionStatus) {
      if (permissionStatus == PermissionStatus.granted) {
        location.onLocationChanged.listen((locationData) {
          if (locationData != null) {
            _locationStreamController.add(UserLocation(
                latitude: locationData.latitude!,
                longitude: locationData.longitude!));
          }
        });
      }
    });
  }

  ///aasd
  ///asd/
  ///aasd
  ///asd/
  ///aasd
  ///asd/
  ///aasd
  ///asd/

  void dispose() => _locationStreamController.close();
}
