import 'dart:async';

import 'package:audiovision/utils/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  String mapTheme = "";
  final Completer<GoogleMapController> _controller = Completer();
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    DefaultAssetBundle.of(context)
        .loadString("assets/maptheme/night_map.json")
        .then((value) {
      mapTheme = value;
    });

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
      _initialPosition = const CameraPosition(
        target: LatLng(37.7749, -122.4194),
        zoom: 14.4746,
      );
    }
  }

  _addPolyLine() {
    PolylineId id = const PolylineId("poly");
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
    final String key = dotenv.env['GOOGLE_MAPS_API_KEYS_AKHA'].toString();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        key,
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
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    _addPolyLine();
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};

    if (widget.startPosition != null && widget.endPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("start"),
          position: LatLng(
            widget.startPosition!.geometry!.location!.lat!,
            widget.startPosition!.geometry!.location!.lng!,
          ),
        ),
      );
      markers.add(
        Marker(
          markerId: const MarkerId("end"),
          position: LatLng(
            widget.endPosition!.geometry!.location!.lat!,
            widget.endPosition!.geometry!.location!.lng!,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Maps Theme"),
        backgroundColor: Colors.blue,
        actions: [
          PopupMenuButton(
              itemBuilder: (context) => [
                    PopupMenuItem(
                        onTap: () {
                          _controller.future.then((value) {
                            DefaultAssetBundle.of(context)
                                .loadString("assets/maptheme/standard_map.json")
                                .then((string) {
                              value.setMapStyle(string);
                            });
                          });
                        },
                        child: const Text("Standard")),
                    PopupMenuItem(
                        onTap: () {
                          _controller.future.then((value) {
                            DefaultAssetBundle.of(context)
                                .loadString("assets/maptheme/retro_map.json")
                                .then((string) {
                              value.setMapStyle(string);
                            });
                          });
                        },
                        child: const Text("Retro")),
                    PopupMenuItem(
                        onTap: () {
                          _controller.future.then((value) {
                            DefaultAssetBundle.of(context)
                                .loadString("assets/maptheme/night_map.json")
                                .then((string) {
                              value.setMapStyle(string);
                            });
                          });
                        },
                        child: const Text("Night")),
                  ])
        ],
        elevation: 5,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: GoogleMap(
        polylines: Set<Polyline>.of(polylines.values),
        initialCameraPosition: _initialPosition,
        markers: Set.from(markers),
        onMapCreated: (GoogleMapController controller) {
          controller.setMapStyle(mapTheme); //for map style
          Future.delayed(const Duration(milliseconds: 2000), () {
            controller.animateCamera(CameraUpdate.newLatLngBounds(
                MapUtils.boundsFromLatLngList(
                    markers.map((loc) => loc.position).toList()),
                1));
            _getPolyline();
          });
        },
      ),
    );
  }
}
