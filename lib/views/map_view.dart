// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:audiovision/controller/scan_controller.dart';
import 'package:audiovision/direction_service.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/services/location_services.dart';
import 'package:audiovision/utils/map_utils.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:audiovision/utils/text_utils.dart';
import 'package:audiovision/widget/object_detected.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
// ned to change the class name, there are two location service
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class MapPage extends StatefulWidget {
  static double userLatitude = 0;
  static double userLongitude = 0;
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _endSearchFieldController = TextEditingController();

  DetailsResult? destination;

  late LatLng destinationCoordinate;

  late FocusNode startFocusNode;
  late FocusNode endFocusNode;

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  Timer? _debounce;

  static LocationService locationService = LocationService();
  late GoogleMapController _mapController;

  Set<Marker> markers = {};
  CameraPosition cameraPosition = CameraPosition(
    target: LatLng(
      MapPage.userLatitude,
      MapPage.userLongitude,
    ),
  );
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  late StreamSubscription _gyroscopeStreamSubscription;
  double _heading = 0.0;

  bool isStartNavigate = false;
  late List<dynamic> allSteps;
  late Map<String, dynamic> endLocation;
  int stepIndex = 0;
  String navigationText = "Heyo";

  double cameraViewX = 0; // Persistent X position
  double cameraViewY = 0; // Persistent Y position

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    googlePlace = GooglePlace(apiKey);

    endFocusNode = FocusNode();

    _listenToUserLocation();

    // _checkDeviceOrientation();
  }

  @override
  void dispose() {
    locationService.dispose();
    _gyroscopeStreamSubscription.cancel();
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
                destination != null ? build_ButtonStart(context) : Container(),

                // isStartNavigate ? cameraView() : Container()
                _build_NavigateBar(context),
                // isStartNavigate
                //     ? Align(
                //         alignment: Alignment.centerRight, child: cameraView())
                //     : Container()
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _listenToUserLocation() {
    // always listen to the user position and update it
    locationService.locationStream.listen((userLocation) async {
      setState(() {
        MapPage.userLatitude = userLocation.latitude;
        MapPage.userLongitude = userLocation.longitude;
        updateUserMarkerPosition(
            LatLng(MapPage.userLatitude, MapPage.userLongitude));
      });
      if (isStartNavigate) {
        if (stepIndex < allSteps.length) {
          // double distanceToStep = await NavigateMethod().calculateDistance(
          //   userLocation.latitude,
          //   userLocation.longitude,
          //   allSteps[stepIndex]['end_lat'],
          //   allSteps[stepIndex]['end_long'],
          // );

          // double destinationDistance = await NavigateMethod().calculateDistance(
          //   userLocation.latitude,
          //   userLocation.longitude,
          //   destinationCoordinate.latitude,
          //   destinationCoordinate.longitude,
          // );

          // Assuming there's a threshold distance to trigger the notification
          double thresholdDistance = 50; // meters
          print("WOYYYYYYYYYYYYYYYYYYYYYYYY");

          // if (distanceToStep <= thresholdDistance) {
          //   String maneuver = allSteps[stepIndex]['maneuver'] ??
          //       'Continue'; // Default to 'Continue' if maneuver is not provided
          //   print("MASIHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH");
          //   print(maneuver);
          //   updateTextNavigate(maneuver);
          //   stepIndex++;
          // }
          // if (destinationDistance <= 10) {
          //   isStartNavigate = false;
          //   print(
          //       "CONGRATULATIONSSSSSSSSSSSSSSSS YOU HAVE REACEHED THE DESTINATION");
          //   stepIndex = 0;
          // }
        }
      }
    });
  }

  //Google Map Widget
  Widget build_GoogleMap(BuildContext context) {
    return GoogleMap(
      polylines: Set<Polyline>.of(polylines.values),
      mapType: MapType.normal,
      initialCameraPosition: cameraPosition,
      onMapCreated: (controller) {
        _mapController = controller;
        setState(() {
          _mapController
              .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        });
      },
      markers: markers,
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
    return !isStartNavigate
        ? Positioned(
            bottom: 30.0,
            right: MediaQuery.of(context).size.width / 2 -
                120.0, // Adjusted to center horizontally
            child: GestureDetector(
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
            ),
          )
        : Container();
  }

  Widget _build_NavigateBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.0, left: 8.0, right: 8.0),
      padding: EdgeInsets.all(12.0), // Adjust the padding as needed
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Color.fromARGB(255, 50, 116, 45),
      ),
      child: Row(
        children: [
          buildArrowDirectionContainer('arrow_upward'),
          Expanded(
            child:
                NowNavigationTextWidget(text: navigationText, fontSize: 18.0),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.mic, color: Colors.blue[400]),
          ),
        ],
      ),
    );
  }

// update the user marker  position
  void updateUserMarkerPosition(LatLng newPosition) {
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
            double minLat =
                MapPage.userLatitude < destinationCoordinate.latitude
                    ? MapPage.userLatitude
                    : destinationCoordinate.latitude;
            double minLng =
                MapPage.userLongitude < destinationCoordinate.longitude
                    ? MapPage.userLongitude
                    : destinationCoordinate.longitude;
            double maxLat =
                MapPage.userLatitude > destinationCoordinate.latitude
                    ? MapPage.userLatitude
                    : destinationCoordinate.latitude;
            double maxLng =
                MapPage.userLongitude > destinationCoordinate.longitude
                    ? MapPage.userLongitude
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
          MapPage.userLatitude,
          MapPage.userLongitude,
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
          target: LatLng(MapPage.userLatitude, MapPage.userLongitude),
          zoom: 17,
          bearing: _heading,
        ),
      ),
    );
    print(LatLng(MapPage.userLatitude, MapPage.userLongitude));
    print(LatLng(
      destination!.geometry!.location!.lat!,
      destination!.geometry!.location!.lng!,
    ));

    isStartNavigate = true;
    get_direction(
      LatLng(MapPage.userLatitude, MapPage.userLongitude),
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
        // print("x");
        // print(event.x * 10.0);
        // print("y");
        // print(event.y * 10.0);
        // print("z");
        // print(event.z * 10.0);
        _heading = event.z * 10.0;
        // print(_heading);
      });
    });
  }

  // cameraView() {
  //   return Container(
  //     height: 200,
  //     child: GetBuilder<ScanController>(
  //       init: ScanController(),
  //       builder: (controller) {
  //         return controller.isCameraInitialized.value
  //             ? Stack(
  //                 children: [
  //                   CameraPreview(controller.cameraController!),
  //                   CustomPaint(
  //                     // Use CustomPaint to draw the bounding box
  //                     painter: BoundingBoxPainter(
  //                         controller.detectionResult, context),
  //                   ),
  //                   DetectedObjectWidget(controller
  //                       .detectionResult), // Display detected object info
  //                   Text("data"),
  //                 ],
  //               )
  //             : const Center(
  //                 child: CircularProgressIndicator(),
  //               );
  //       },
  //     ),
  //   );
  // }

  Widget cameraView() {
    return Stack(
      children: [
        Positioned(
          left: cameraViewX,
          top: cameraViewY,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                // Update the position of the camera view based on user drag
                cameraViewX += details.delta.dx;
                cameraViewY += details.delta.dy;
              });
            },
            child: Container(
              height: 200,
              width: 150, // Example width of the camera view
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
                      : Center(
                          child: CircularProgressIndicator(),
                        );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void updateTextNavigate(String newData) {
    setState(() {
      navigationText = newData;
    });
  }

  Future<Map<String, dynamic>> get_direction(
    LatLng user_position,
    LatLng destination,
  ) async {
    bool isNavigate = true;
    final String url_using_latlong =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${user_position.latitude},${user_position.longitude}&"
        "destination=${destination.latitude},${destination.longitude}&"
        "mode=walking&"
        "key=AIzaSyCgjkSHUOL0bgO4w94tC4Z6je-7303-Jn4"; //WARNINGG !!!

    var response = await http.get(Uri.parse(url_using_latlong));
    var json = convert.jsonDecode(response.body);

    List<dynamic> routes = json['routes'];
    Map<String, dynamic> results = {
      'bounds_ne': routes[0]['bounds']['northeast'],
      'bounds_sw': routes[0]['bounds']['southwest'],
      'start_location': routes[0]['legs'][0]['start_location'],
      'end_location': routes[0]['legs'][0]['end_location'],
      'polyline': routes[0]['overview_polyline']['points'],
      'polyline_decoded': PolylinePoints()
          .decodePolyline(routes[0]['overview_polyline']['points']),
    };

    if (routes.isNotEmpty) {
      List<dynamic> legs = routes[0]['legs'];
      if (legs.isNotEmpty) {
        List<dynamic> steps = legs[0]['steps'];
        List<Map<String, dynamic>> stepResults = [];
        for (var step in steps) {
          Map<String, dynamic> stepResult = {
            'distance': step['distance']['text'],
            'duration': step['duration']['text'],
            'end_lat': step['start_location']['lat'],
            'end_long': step['start_location']['lng'],
            'instructions':
                DirectionServcie().removeHtmlTags(step['html_instructions']),
          };

          if (step.containsKey('maneuver')) {
            stepResult['maneuver'] = step['maneuver'];
          }

          stepResults.add(stepResult);
        }

        results['steps'] = stepResults;
        allSteps = results['steps'];
        endLocation = results['end_location'];
      }
    }

    // print('Bounds NE: ${results['bounds_ne']}');
    // print('Bounds SW: ${results['bounds_sw']}');
    // print('Start Location: ${results['start_location']}');
    // print('End Location: ${results['end_location']}');
    // print('Polyline: ${results['polyline']}');
    // print('Polyline Decoded: ${results['polyline_decoded']}');
    // print('Steps:');
    // while (isNavigate) {
    // int x = 0;
    // while (isStartNavigate) {
    //   // Obtain the user's current location inside the loop
    //   double userLatitude = MapPage.userLatitude;
    //   double userLongitude = MapPage.userLongitude;

    //   List<dynamic> steps = results['steps'];
    //   while (x < steps.length) {
    //     double distanceToStep = await calculateDistance(
    //       userLatitude,
    //       userLongitude,
    //       steps[x]['end_lat'],
    //       steps[x]['end_long'],
    //     );

    //     double destinationDistance = await calculateDestinationDistance(
    //       userLatitude,
    //       userLongitude,
    //     );

    //     // Assuming there's a threshold distance to trigger the notification
    //     double thresholdDistance = 50; // meters
    //     print("WOYYYYYYYYYYYYYYYYYYYYYYYY");

    //     if (distanceToStep <= thresholdDistance) {
    //       String maneuver = steps[x]['maneuver'] ??
    //           'Continue'; // Default to 'Continue' if maneuver is not provided
    //       print("MASIHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH");
    //       print(maneuver);
    //       updateTextNavigate(maneuver);
    //       // break; // Exit loop after notifying the user about the next maneuver
    //     }
    //     if (destinationDistance <= 5) {
    //       isStartNavigate = false;
    //       print("CONGRATULATIONSSSSSSSSSSSSSSSS");
    //     }
    //     // String textToSpeak =
    //     //     'Jarak: ${step['distance']}, Durasi: ${step['duration']}, Instruksi: ${step['instructions']}';
    //     // if (step.containsKey('maneuver')) {
    //     //   textToSpeak += ', Manuver: ${step['maneuver']}';
    //     // }
    //     // await speak(textToSpeak);
    //     // await Future.delayed(Duration(seconds: 3));
    //     // await speakWithCompletion(textToSpeak);
    //     x++;
    //   }
    //   if (isStartNavigate) {
    //     x = 0;
    //     _listenToUserLocation();
    //   }
    // }

    // }

    return results;
  }

  Future<double> calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) async {
    double distanceInMeters = await Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
    return distanceInMeters;
  }

  Future<double> calculateDestinationDistance(
      double startLatitude, double startLongitude) async {
    double distanceInMeters = await Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        destinationCoordinate.latitude,
        destinationCoordinate.longitude);
    return distanceInMeters;
  }
}
