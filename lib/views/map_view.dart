import 'dart:async';

import 'package:audiovision/services/location_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

class MyMap extends StatefulWidget {
  const MyMap({super.key});

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  final _endSearchFieldController = TextEditingController();

  DetailsResult? startPosition;
  DetailsResult? endPosition;

  late FocusNode startFocusNode;
  late FocusNode endFocusNode;

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  Timer? _debounce;
  static double latitude = 0;
  static double longitude = 0;

  static LocationService locationService = LocationService();
  late GoogleMapController _controller;

  Set<Marker> markers = {};
  CameraPosition cameraPosition = CameraPosition(
    target: LatLng(
      latitude,
      longitude,
    ),
  );
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  Set<Polyline> _polylines = Set<Polyline>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    googlePlace = GooglePlace(apiKey);

    endFocusNode = FocusNode();

    locationService.locationStream.listen((userLocation) {
      setState(() {
        latitude = userLocation.latitude;
        longitude = userLocation.longitude;
        startPosition = DetailsResult(
          // Assign latitude and longitude values
          geometry: Geometry(
            location: Location(
              lat: userLocation.latitude,
              lng: userLocation.longitude,
            ),
          ),
        );
        updateUserLocation(LatLng(latitude, longitude));
      });
    });
  }

  @override
  void dispose() {
    locationService.dispose();
    super.dispose();
  }

  void autoCompleteSearch(String value) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      print(result.predictions!.first.description);
      setState(() {
        predictions = result.predictions!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 100),
          TextField(
            controller: _endSearchFieldController,
            autofocus: false,
            focusNode: endFocusNode,
            style: const TextStyle(fontSize: 24),
            decoration: InputDecoration(
              hintText: "Search Here",
              hintStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: const BorderSide(width: 0, style: BorderStyle.none),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.all(15),
              suffixIcon: _endSearchFieldController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          predictions = [];
                          _endSearchFieldController.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_outlined),
                    )
                  : null,
            ),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 1000), () {
                if (value.isNotEmpty) {
                  autoCompleteSearch(value);
                } else {
                  setState(() {
                    predictions = [];
                    endPosition = null;
                  });
                }
              });
            },
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  polylines: Set<Polyline>.of(polylines.values),
                  mapType: MapType.normal,
                  initialCameraPosition: cameraPosition,
                  onMapCreated: (controller) {
                    _controller = controller;
                  },
                  onTap: (points) {
                    print("object");
                  },
                  markers: markers,
                  onCameraIdle: () {
                    setState(() {});
                  },
                ),
                predictions.isNotEmpty
                    ? ListView.builder(
                        itemCount: predictions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.pin_drop,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              predictions[index].description.toString(),
                            ),
                            onTap: () async {
                              final placeId = predictions[index].placeId!;
                              final details =
                                  await googlePlace.details.get(placeId);
                              if (details != null &&
                                  details.result != null &&
                                  mounted) {
                                if (endFocusNode.hasFocus) {
                                  setState(() {
                                    endPosition = details.result;
                                    _endSearchFieldController.text =
                                        details.result!.name!;
                                    predictions = [];
                                    markers.add(
                                      Marker(
                                        markerId: MarkerId("planceName"),
                                        position: LatLng(
                                          endPosition!.geometry!.location!.lat!,
                                          endPosition!.geometry!.location!.lng!,
                                        ),
                                      ),
                                    );
                                    _getPolyline(
                                        endPosition!.geometry!.location!.lat!,
                                        endPosition!.geometry!.location!.lng!);
                                  });
                                }
                                print("Start Position: $startPosition");
                                print("End Position: $endPosition");
                              }
                            },
                          );
                        },
                      )
                    : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void updateUserLocation(LatLng newPosition) {
    setState(() {
      cameraPosition = CameraPosition(target: newPosition, zoom: 16.5);
      // Update marker for user's position or add it if not present
      markers.removeWhere((marker) => marker.markerId.value == "You");
      markers.add(
        Marker(
          markerId: const MarkerId("You"),
          position: newPosition,
        ),
      );
    });
    _controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
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

  _getPolyline(end_latitude, end_longitude) async {
    final String key = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        key,
        PointLatLng(
          latitude,
          longitude,
        ),
        PointLatLng(
          end_latitude,
          end_longitude,
        ),
        travelMode: TravelMode.walking);

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    _addPolyLine();
  }
}
