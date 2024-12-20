import 'dart:ffi';
import 'dart:typed_data';

import 'package:audiovision/pages/auth_page/services/auth_services.dart';
import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/marker_method.dart';
import 'package:audiovision/pages/map_page/method/polyline_mothod.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart'; // Import the services library for clipboard functionality

class ShareLocation {
  static late DatabaseReference dbRef;

  //tracking
  static bool isTracking = false;
  static String? trackingUserName;
  static String? trackingDestinationLocationName;
  static String? nearLocationAddress;
  static LatLng? trackUserCoordinate;
  static LatLng? trackDestinationCoordinate;
  static double? totalDistance;
  static int? totalDuration;

// update shared data
  static bool isShared = false;
  static shareUserLocation(
    LatLng userLocation,
    LatLng destinationLocation,
    double total_distance,
    int total_duration,
    String destinationLocationName,
    String near_location_address,
  ) async {
    isShared = true;
    final userRef = dbRef.child(AuthService.userName.toString());
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      // ID exists, remove the existing data
      await userRef.remove();
    }

    // Set the new data
    await userRef.set({
      'name': AuthService.userName,
      'totalDistance': total_distance,
      'totalDuration': total_duration,
      'userLocation': {
        "lat": userLocation.latitude,
        "long": userLocation.longitude
      },
      'nearLocationAddress': near_location_address,
      'destinationLocationName': destinationLocationName,
      'destinationLocation': {
        "lat": destinationLocation.latitude,
        "long": destinationLocation.longitude
      },
    });

    TextToSpeech.speak(
        "start sharing your location, share your username with other people");
  }

  static updateUserLocationToFirebase(LatLng userLocation) {
    // Mengirim data ke Firebase Realtime Database
    dbRef.child(AuthService.userName.toString()).update({
      'userLocation': {
        "lat": userLocation.latitude,
        "long": userLocation.longitude
      },
    });
  }

  static getOtherUserLocation() async {
    // Check if trackingUserName is empty
    if (trackingUserName == null || trackingUserName!.isEmpty) {
      // Handle empty tracking ID here (e.g., show an error message)
      return;
    }

    final snapshot = await dbRef.child(trackingUserName!).get();

    if (snapshot.exists) {
      // Data exists, you can access it using snapshot.value
      dynamic userData = snapshot.value;

      // Extract userLocation data
      dynamic userLocationData = userData['userLocation'];
      dynamic destinationLocationData = userData['destinationLocation'];

      trackingUserName = userData['name'];
      nearLocationAddress = userData['nearLocationAddress'];
      totalDistance = userData['totalDistance'];
      totalDuration = userData['totalDuration'];

      // Assign the location name and coordinates trackUserCoordinate
      trackingDestinationLocationName = userData['destinationLocationName'];

      trackUserCoordinate =
          LatLng(userLocationData['lat'], userLocationData['long']);
      trackDestinationCoordinate = LatLng(
          destinationLocationData['lat'], destinationLocationData['long']);

      print(snapshot.value);
      final Uint8List markerDestination = await MarkerMethod.getBytesFromAsset(
          'assets/markers/destination-marker.png', 100);
      MapPage.markers.add(
        Marker(
          markerId:
              const MarkerId("Tracking Destination"), // Assert non-null using !
          position: LatLng(ShareLocation.trackDestinationCoordinate!.latitude,
              ShareLocation.trackDestinationCoordinate!.longitude),
          // Custom marker icon
          icon: BitmapDescriptor.fromBytes(markerDestination),
          infoWindow:
              InfoWindow(title: ShareLocation.trackingDestinationLocationName),
        ),
      );
      //  Navigator.of(context).pop();
      //Navigator.of(context).pop();
      isTracking = true;

      // Close the dialog
    } else {
      print('No data available.');
    }
  }

  static checkOtherUser(String userName, BuildContext context) async {
    final snapshot = await dbRef.child(userName).get();

    if (snapshot.exists) {
      trackingUserName = userName;
      Navigator.of(context).pop(); // trackClose the dialog
      MapPage.panelHeightClosed = MediaQuery.of(context).size.height * 0.35;
      MapPage.panelHeightOpen = MediaQuery.of(context).size.height * 0.35;
      getOtherUserLocation();
    } else {
      TextToSpeech.speak(
          'There is no shared data location name with $userName');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('There is no shared data location name with $userName'),
        ),
      );
    }
  }

  static stopTracking() {
    trackDestinationCoordinate = null;
    PolylineMethod(stopTracking)
        .clearPolyline(); // stop tracking did not use in clearPolyline method

    MapPage.markers.removeWhere(
      (marker) => marker.markerId.value == ShareLocation.trackingUserName!,
    );

    // Update marker for user's position or add it if not present
    MapPage.markers.removeWhere(
      (marker) => marker.markerId.value == "Tracking Destination",
    );
    isTracking = false;

    trackingUserName = null;
    trackUserCoordinate = null;
  }
}
