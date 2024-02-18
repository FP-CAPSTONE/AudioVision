import 'package:audiovision/pages/map_page/map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatelessWidget {
  GoogleMapWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      polylines: Set<Polyline>.of(MapPage.polylines.values),
      mapType: MapType.normal,
      initialCameraPosition: MapPage.cameraPosition,
      onMapCreated: (controller) {
        MapPage.mapController = controller;
        MapPage.mapController!.animateCamera(
            CameraUpdate.newCameraPosition(MapPage.cameraPosition));
      },
      markers: MapPage.markers,
    );
  }
}
