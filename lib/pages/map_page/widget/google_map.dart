import 'package:audiovision/pages/map_page/map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatefulWidget {
  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  bool _isCameraPositionSet = false;

  @override
  Widget build(BuildContext context) {
    return _isCameraPositionSet ? _buildMap() : _buildLoadingIndicator();
  }

  Widget _buildMap() {
    return GoogleMap(
      polylines: Set<Polyline>.of(MapPage.polylines.values),
      mapType: MapType.normal,
      initialCameraPosition: MapPage.cameraPosition,
      onMapCreated: (controller) {
        MapPage.mapController = controller;
        MapPage.mapController!.animateCamera(
          CameraUpdate.newCameraPosition(MapPage.cameraPosition),
        );
      },
      markers: MapPage.markers,
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator());
  }

  @override
  void initState() {
    super.initState();
    _waitForCameraPosition();
  }

  Future<void> _waitForCameraPosition() async {
    while (MapPage.cameraPosition.target.latitude == 0 ||
        MapPage.cameraPosition.target.longitude == 0) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    setState(() {
      _isCameraPositionSet = true;
    });
  }
}
