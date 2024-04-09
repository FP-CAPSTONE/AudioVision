import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPrintService {
  static void printLocationFromDatabase(String userId) {
    Timer.periodic(Duration(minutes: 1), (timer) async {
      // Ambil lokasi dari database
      DocumentSnapshot locationSnapshot = await FirebaseFirestore.instance
          .collection('livelocation')
          .doc(userId)
          .get();

      // Cetak lokasi ke konsol jika data tersedia
      if (locationSnapshot.exists) {
        double? latitude = locationSnapshot['latitude'];
        double? longitude = locationSnapshot['longitude'];

        if (latitude != null && longitude != null) {
          print(
              'Location from Database: Latitude: $latitude, Longitude: $longitude');
        } else {
          print('Invalid or missing data in Database');
        }
      } else {
        print('Location not found in Database');
      }
    });
  }
}

