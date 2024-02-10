import 'dart:async';

import 'package:audiovision/utils/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

class MapScreen extends StatefulWidget {
  final DetailsResult? startPosition;
  final DetailsResult? endPosition;
  const MapScreen({Key? key, this.startPosition, this.endPosition})
      : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late CameraPosition _initialPosition;
  final Completer<GoogleMapController> _controller = Completer();
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    if (widget.startPosition != null &&
        widget.startPosition!.geometry != null &&
        widget.startPosition!.geometry!.location != null) {
      _initialPosition = CameraPosition(
          target: LatLng(
            widget.startPosition!.geometry!.location!.lat!,
            widget.startPosition!.geometry!.location!.lng!,
          ),
          zoom: 14.4746);
    } else {
      // Handle case where startPosition or its properties are null
      // For example, you could set a default initial position
      _initialPosition = CameraPosition(
        target: LatLng(37.7749, -122.4194),
        zoom: 14.4746,
      );
    }
  }

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  _getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        "AIzaSyAybdbxkw5RNXO9Yg0O7FWFe31M8MwFllM",
        PointLatLng(
          widget.startPosition!.geometry!.location!.lat!,
          widget.startPosition!.geometry!.location!.lng!,
        ),
        PointLatLng(
          widget.endPosition!.geometry!.location!.lat!,
          widget.endPosition!.geometry!.location!.lng!,
        ),
        travelMode: TravelMode.driving);

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    _addPolyLine();
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> _markers = {};

    if (widget.startPosition != null && widget.endPosition != null) {
      _markers.add(
        Marker(
          markerId: MarkerId("start"),
          position: LatLng(
            widget.startPosition!.geometry!.location!.lat!,
            widget.startPosition!.geometry!.location!.lng!,
          ),
        ),
      );
      _markers.add(
        Marker(
          markerId: MarkerId("end"),
          position: LatLng(
            widget.endPosition!.geometry!.location!.lat!,
            widget.endPosition!.geometry!.location!.lng!,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: CircleAvatar(
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: GoogleMap(
        polylines: Set<Polyline>.of(polylines.values),
        initialCameraPosition: _initialPosition,
        markers: Set.from(_markers),
        onMapCreated: (GoogleMapController controller) {
          Future.delayed(Duration(milliseconds: 2000), () {
            controller.animateCamera(CameraUpdate.newLatLngBounds(
                MapUtils.boundsFromLatLngList(
                    _markers.map((loc) => loc.position).toList()),
                1));
            _getPolyline();
          });
        },
      ),
    );
  }
}
