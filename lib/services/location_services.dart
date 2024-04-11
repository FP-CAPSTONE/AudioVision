import 'dart:async';

<<<<<<< HEAD
import 'package:audiovision/services/firebase_realtime.dart';
import 'package:audiovision/services/user_location.dart';
import 'package:firebase_database/firebase_database.dart';
=======
import 'package:audiovision/services/user_location.dart';
>>>>>>> map_guidance
import 'package:location/location.dart';

class LocationService {
  Location location = Location();
  final StreamController<UserLocation> _locationStreamController =
      StreamController<UserLocation>.broadcast();
  Stream<UserLocation> get locationStream => _locationStreamController.stream;

  LocationService() {
<<<<<<< HEAD
    location.requestPermission().then((permissionStatus) {
      if (permissionStatus == PermissionStatus.granted) {
        Timer.periodic(Duration(minutes: 1), (Timer timer) {
          sendLocationData();
        });
      }
    });
  }

  void sendLocationData() {
    location.getLocation().then((locationData) {
      if (locationData != null) {
        _locationStreamController.add(UserLocation(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
        ));

        updateLocationData(CurrentLocationData(
          name: 'John',
          coordinates: [
            Coordinate(
              latitude: locationData.latitude!,
              longitude: locationData.longitude!,
              timestamp: DateTime.now(),
            ),
          ],
        ));
      }
    });
  }

  void updateLocationData(CurrentLocationData locationData) {
    final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

    // Mengirim data ke Firebase Realtime Database
    databaseReference.child('livetracking').set({
      'name': locationData.name,
      'coordinates': locationData.coordinates
          .map((coordinate) => coordinate.toJson())
          .toList(),
    });

    print('Updating location data: $locationData');
=======
    location.requestPermission().then(
      (permissionStatus) {
        if (permissionStatus == PermissionStatus.granted) {
          location.onLocationChanged.listen(
            (locationData) {
              _locationStreamController.add(
                UserLocation(
                  latitude: locationData.latitude!,
                  longitude: locationData.longitude!,
                ),
              );
            },
          );
        }
      },
    );
>>>>>>> map_guidance
  }

  void dispose() => _locationStreamController.close();
}
