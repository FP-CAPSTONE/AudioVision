// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:audiovision/direction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'utils/text_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required by FlutterConfig
  await FlutterConfig.loadEnvVariables();

  runApp(MyAudioGuide());
}

class MyAudioGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

  Set<Marker> _markers = Set<Marker>();
  Set<Polygon> _polygons = Set<Polygon>();
  Set<Polyline> _polylines = Set<Polyline>();

  List<LatLng> polygonLatLngs = <LatLng>[];

  int _polygonsIdCounter = 1;
  int _polylineIdCounter = 1;

  bool isFirstRowVisible = true;
  bool isSecondsRowVisible = false;

  String _getCurrentTime() {
    DateTime now = DateTime.now();
    String formattedTime = "${now.hour}:${now.minute}";
    return formattedTime;
  }

  // Tambahkan variabel ini

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();

    _setMarker(LatLng(37.42796133580664, -122.085749655962));
  }

  void _setMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(markerId: MarkerId('marker'), position: point),
      );
    });
  }

  void _setPolygon() {
    final String polygonIdVal = 'polygon_$_polygonsIdCounter';
    _polygonsIdCounter++;

    _polygons.add(Polygon(
      polygonId: PolygonId(polygonIdVal),
      points: polygonLatLngs,
      strokeWidth: 2,
      fillColor: Colors.transparent,
    ));
  }

  void _setPolylines(List<PointLatLng> points) {
    final String polylineIdVal = 'polyline_$_polylineIdCounter';
    _polylineIdCounter++;

    _polylines.add(Polyline(
      polylineId: PolylineId(polylineIdVal),
      width: 2,
      color: Colors.blue,
      points: points
          .map(
            (point) => LatLng(point.latitude, point.longitude),
          )
          .toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maps Guide'),
      ),
      body: Column(
        children: [
          Visibility(
            visible: isFirstRowVisible,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _originController,
                        decoration: InputDecoration(hintText: 'Origin'),
                        onChanged: (value) {
                          print(value);
                        },
                      ),
                      TextFormField(
                        controller: _destinationController,
                        decoration: InputDecoration(hintText: 'Destination'),
                        onChanged: (value) {
                          print(value);
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    var directions = await DirectionServcie().getDirections(
                      _originController.text,
                      _destinationController.text,
                    );
                    _goToPlace(
                      directions['start_location']['lat'],
                      directions['start_location']['lng'],
                      directions['bounds_ne'],
                      directions['bounds_sw'],
                    );

                    _setPolylines(directions['polyline_decoded']);

                    // Setelah tombol diklik, sembunyikan bagian Row
                    setState(() {
                      isFirstRowVisible = false;
                      isSecondsRowVisible = true;
                    });
                  },
                  icon: Icon(Icons.search),
                ),
              ],
            ),
          ),
          Visibility(
            visible: isSecondsRowVisible,
            child: Container(
              margin: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              padding: EdgeInsets.all(12.0), // Adjust the padding as needed
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                  bottomRight: Radius.circular(
                      10.0), // Setting this to 0.0 makes the bottom-right corner square
                  bottomLeft: Radius.circular(
                      0.0), // Setting this to 0.0 makes the bottom-left corner square
                ),
                color: Color.fromARGB(255, 50, 116, 45),
              ),
              child: Row(
                children: [
                  buildArrowDirectionContainer('arrow_upward'),
                  Expanded(
                    child: NowNavigationTextWidget(
                        text: "Head North", fontSize: 18.0),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.mic, color: Colors.blue[400]),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: isSecondsRowVisible,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 5.0),
                width: 100.0, // Set the desired width
                padding: EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(0.0),
                    topRight: Radius.circular(0.0),
                    bottomRight: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0),
                  ),
                  color: Color.fromARGB(255, 28, 71, 26),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 8.0), // Add left margin
                          child: NowNavigationTextWidget(
                            text: "Then",
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    buildArrowDirectionContainer('arrow_forward'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              markers: _markers,
              polygons: _polygons,
              polylines: _polylines,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onTap: (points) {
                setState(() {
                  polygonLatLngs.add(points);
                  _setPolygon();
                });
              },
            ),
          ),
          Visibility(
            visible: isSecondsRowVisible,
            child: Container(
              margin: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              padding: EdgeInsets.all(12.0), // Adjust the padding as needed
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                  bottomRight: Radius.circular(
                      10.0), // Setting this to 0.0 makes the bottom-right corner square
                  bottomLeft: Radius.circular(
                      0.0), // Setting this to 0.0 makes the bottom-left corner square
                ),
              ),
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 10.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withOpacity(0.4)),
                    ),
                    child: Icon(Icons.close, size: 30.0, color: Colors.black),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        NowNavigationTextWidget(
                          text: "17 min",
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                        NowNavigationTextWidget(
                          text: "12 km | ${_getCurrentTime()}",
                          fontSize: 12.0,
                          color: Colors.black.withOpacity(0.4),
                          bold: false,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 10.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withOpacity(0.4)),
                    ),
                    child: buildArrowDirectionContainer('call_split',
                        color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToPlace(
    double lat,
    double lng,
    Map<String, dynamic> boundsNe,
    Map<String, dynamic> boundsSw,
  ) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12),
      ),
    );

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng']),
          ),
          25),
    );
    _setMarker(LatLng(lat, lng));
  }
}
