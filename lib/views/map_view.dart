// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:audiovision/controller/scan_controller.dart';
import 'package:audiovision/services/location_services.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:audiovision/widget/object_detected.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
// ned to change the class name, there are two location service
import 'package:audiovision/direction_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MyMap extends StatefulWidget {
  const MyMap({super.key});

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  final _endSearchFieldController = TextEditingController();

  DetailsResult? destination;

  late LatLng destinationCoordinate;

  late FocusNode startFocusNode;
  late FocusNode endFocusNode;

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  Timer? _debounce;
  static double userLatitude = 0;
  static double userLongitude = 0;

  static LocationService locationService = LocationService();
  late GoogleMapController _mapController;

  Set<Marker> markers = {};
  CameraPosition cameraPosition = CameraPosition(
    target: LatLng(
      userLatitude,
      userLongitude,
    ),
  );
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  late StreamSubscription _gyroscopeStreamSubscription;
  double _heading = 0.0;

  bool isStartNavigate = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    googlePlace = GooglePlace(apiKey);

    endFocusNode = FocusNode();

    // always listen to the user position and update it
    locationService.locationStream.listen((userLocation) {
      setState(() {
        userLatitude = userLocation.latitude;
        userLongitude = userLocation.longitude;
        updateUserLocation(LatLng(userLatitude, userLongitude));
      });
    });

    _checkDeviceOrientation();
  }

  @override
  void dispose() {
    locationService.dispose();
    _gyroscopeStreamSubscription?.cancel();
    super.dispose();
  }

  void autoCompleteSearch(String value) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      // print(result.predictions!.first.description);
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
          Expanded(
            child: Stack(
              children: [
                build_GoogleMap(context),
                build_SearchBar(context),
                build_ButtonStart(context),
                isStartNavigate ? cameraView() : Container()
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Google Map Widget
  Widget build_GoogleMap(BuildContext context) {
    return GoogleMap(
      polylines: Set<Polyline>.of(polylines.values),
      mapType: MapType.normal,
      initialCameraPosition: cameraPosition,
      onMapCreated: (controller) {
        _mapController = controller;
        _mapController
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      },
      markers: markers,
      onCameraIdle: () {
        setState(() {
          // _mapController.animateCamera(
          //   CameraUpdate.newCameraPosition(
          //     CameraPosition(
          //       target: LatLng(userLatitude, userLongitude),
          //       zoom: 17,
          //       bearing: _heading,
          //     ),
          //   ),
          // );
        });
      },
    );
  }

  //Search Bar Widget
  Widget build_SearchBar(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 100),
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
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
              borderSide: BorderSide(width: 0, style: BorderStyle.none),
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
                  destination = null;
                });
              }
            });
          },
        ),
        predictions.isNotEmpty
            ? Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: predictions.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onLongPress: () {
                        TextToSpeech.speak(
                            predictions[index].description.toString());
                      },
                      child: Container(
                        color: Colors.white,
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.pin_drop,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            predictions[index].description.toString(),
                          ),
                          onTap: () {
                            add_destination(index);
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
            : Container(),
      ],
    );
  }

  //Start Button Widget
  Widget build_ButtonStart(BuildContext context) {
    return Positioned(
      bottom: 30.0,
      right: MediaQuery.of(context).size.width / 2 -
          120.0, // Adjusted to center horizontally
      child: destination != null
          ? GestureDetector(
              onLongPress: () => TextToSpeech.speak("Start Navigation Button"),
              child: SizedBox(
                width: 240.0, // Set the width of the button
                height: 60.0, // Set the height of the button
                child: Material(
                  elevation: 8.0, // Set the elevation (shadow) value
                  borderRadius:
                      BorderRadius.circular(30.0), // Set border radius
                  color: Colors.blue, // Set background color
                  child: InkWell(
                    onTap: () {
                      // Add your button functionality here
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (context) => CameraaView()),
                      // );

                      _startNavigate();
                      isStartNavigate = true;
                    },
                    borderRadius: BorderRadius.circular(
                      30.0,
                    ), // Set border radius for the InkWell
                    child: const Center(
                      child: Text(
                        'Start Navigation',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w500), // Set text size
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Container(),
    );
  }

// always update the user position
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

    if (destination != null) {
      // _mapController.animateCamera(CameraUpdate.newCameraPosition(
      //   LatLngBounds(
      //     southwest: newPosition,
      //     northeast: LatLng(
      //       destination!.geometry!.location!.lat!,
      //       destination!.geometry!.location!.lng!,
      //     ),
      //   ),
      //   50, // Padding
      // ));
      _getPolyline(destinationCoordinate);
    }
  }

// add destination when user clck the listview
  void add_destination(int index) async {
    final placeId = predictions[index].placeId!;
    final details = await googlePlace.details.get(placeId);
    if (details != null && details.result != null && mounted) {
      if (endFocusNode.hasFocus) {
        setState(
          () {
            destination = details.result;
            _endSearchFieldController.text = details.result!.name!;
            predictions = [];
            _clearPolyline();
            markers
                .removeWhere((marker) => marker.markerId.value == "planceName");
            //asgin destinationCoordinate variable
            destinationCoordinate = LatLng(
              destination!.geometry!.location!.lat!,
              destination!.geometry!.location!.lng!,
            );
            markers.add(
              Marker(
                markerId: const MarkerId("planceName"),
                position: destinationCoordinate,
              ),
            );

            // find the north and south to animate the camera
            double minLat = userLatitude < destinationCoordinate.latitude
                ? userLatitude
                : destinationCoordinate.latitude;
            double minLng = userLongitude < destinationCoordinate.longitude
                ? userLongitude
                : destinationCoordinate.longitude;
            double maxLat = userLatitude > destinationCoordinate.latitude
                ? userLatitude
                : destinationCoordinate.latitude;
            double maxLng = userLongitude > destinationCoordinate.longitude
                ? userLongitude
                : destinationCoordinate.longitude;

            _mapController.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(minLat, minLng),
                  northeast: LatLng(maxLat, maxLng),
                ),
                100, // Padding
              ),
            );

            _getPolyline(destinationCoordinate);
          },
        );
      }
    }
  }

  void _getPolyline(LatLng destinationCoordinate) async {
    final String key = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        key,
        PointLatLng(
          userLatitude,
          userLongitude,
        ),
        PointLatLng(
          destinationCoordinate.latitude,
          destinationCoordinate.longitude,
        ),
        travelMode: TravelMode.walking);
    // clear polyline first before update the polyline
    _clearPolyline();
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    _addPolyLine();
  }

  void _addPolyLine() {
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

  void _clearPolyline() {
    polylineCoordinates.clear();
    polylines.clear();
    setState(() {});
  }

  void _startNavigate() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(userLatitude, userLongitude),
            zoom: 17,
            bearing: _heading),
      ),
    );
    DirectionServcie().get_direction(
      LatLng(userLatitude, userLongitude),
      LatLng(
        destination!.geometry!.location!.lat!,
        destination!.geometry!.location!.lng!,
      ),
    );
  }

  void _checkDeviceOrientation() {
    // Store the subscription returned by accelerometerEvents.listen()
    _gyroscopeStreamSubscription =
        gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        print("x");
        print(event.x * 10.0);
        print("y");
        print(event.y * 10.0);
        print("z");
        print(event.z * 10.0);
        _heading = event.z * 10.0;
        // print(_heading);
      });
    });
  }

  cameraView() {
    return Container(
      height: 200,
      child: GetBuilder<ScanController>(
        init: ScanController(),
        builder: (controller) {
          return controller.isCameraInitialized.value
              ? Stack(
                  children: [
                    CameraPreview(controller.cameraController!),
                    CustomPaint(
                      // Use CustomPaint to draw the bounding box
                      painter: BoundingBoxPainter(
                          controller.detectionResult, context),
                    ),
                    DetectedObjectWidget(controller
                        .detectionResult), // Display detected object info
                    Text("data"),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                );
        },
      ),
    );
  }
}
