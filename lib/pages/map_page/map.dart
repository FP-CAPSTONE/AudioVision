// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:audiovision/pages/map_page/method/location_method.dart';
import 'package:audiovision/pages/map_page/method/polyline_mothod.dart';
import 'package:audiovision/pages/map_page/widget/button_start.dart';
import 'package:audiovision/pages/map_page/widget/camera_view.dart';
import 'package:audiovision/pages/map_page/widget/google_map.dart';
import 'package:audiovision/pages/map_page/widget/navigate_bar.dart';
import 'package:audiovision/services/location_services.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:riverpod/riverpod.dart';
// ned to change the class name, there are two location service
import 'package:sensors_plus/sensors_plus.dart';

class MapPage extends StatefulWidget {
  //public variable
  static double userLatitude = 0;
  static double userLongitude = 0;
  static LatLng destinationCoordinate = const LatLng(0, 0);

  static bool isStartNavigate = false;

  static GoogleMapController? mapController;

  static List<dynamic> allSteps = [];
  static Map<String, dynamic> endLocation = {};

  static CameraPosition cameraPosition = CameraPosition(
    target: LatLng(
      userLatitude,
      userLongitude,
    ),
  );

  static Map<PolylineId, Polyline> polylines = {};

  static Set<Marker> markers = {};
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _endSearchFieldController = TextEditingController();

  DetailsResult? destination;

  late FocusNode startFocusNode;
  late FocusNode endFocusNode;

  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  Timer? _debounce;

  static LocationService locationService = LocationService();

  late StreamSubscription _gyroscopeStreamSubscription;
  double _heading = 0.0;

  int stepIndex = 0;
  String navigationText = "Heyo";

  double cameraViewX = 0; // Persistent X position
  double cameraViewY = 0; // Persistent Y position
  void updatePolyline(newPolylines) {
    PolylineId id = const PolylineId("poly");

    setState(() => MapPage.polylines[id] = newPolylines);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    googlePlace = GooglePlace(apiKey);

    endFocusNode = FocusNode();

    LocationMethod().listenToUserLocation(locationService);

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
                GoogleMapWidget(),
                build_SearchBar(context),
                destination != null
                    ? ButtonStartNavigateWidget(
                        mapController: MapPage.mapController!)
                    : Container(),
                NavigateBarWidget(navigationText: navigationText),
                MapPage.isStartNavigate ? _builCamera() : Container(),
                // isStartNavigate
                // ? Align(
                //     alignment: Alignment.centerRight, child: cameraView())
                // : Container()
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
      polylines: Set<Polyline>.of(MapPage.polylines.values),
      mapType: MapType.normal,
      initialCameraPosition: MapPage.cameraPosition,
      onMapCreated: (controller) {
        MapPage.mapController = controller;
        setState(() {
          MapPage.mapController!.animateCamera(
              CameraUpdate.newCameraPosition(MapPage.cameraPosition));
        });
      },
      markers: MapPage.markers,
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
            MapPage.markers
                .removeWhere((marker) => marker.markerId.value == "planceName");
            //asgin MapPage.destinationCoordinate variable
            MapPage.destinationCoordinate = LatLng(
              destination!.geometry!.location!.lat!,
              destination!.geometry!.location!.lng!,
            );
            MapPage.markers.add(
              Marker(
                markerId: const MarkerId("planceName"),
                position: MapPage.destinationCoordinate,
              ),
            );

            // find the north and south to animate the camera
            double minLat =
                MapPage.userLatitude < MapPage.destinationCoordinate.latitude
                    ? MapPage.userLatitude
                    : MapPage.destinationCoordinate.latitude;
            double minLng =
                MapPage.userLongitude < MapPage.destinationCoordinate.longitude
                    ? MapPage.userLongitude
                    : MapPage.destinationCoordinate.longitude;
            double maxLat =
                MapPage.userLatitude > MapPage.destinationCoordinate.latitude
                    ? MapPage.userLatitude
                    : MapPage.destinationCoordinate.latitude;
            double maxLng =
                MapPage.userLongitude > MapPage.destinationCoordinate.longitude
                    ? MapPage.userLongitude
                    : MapPage.destinationCoordinate.longitude;

            PolylineMethod(updatePolyline).getPolyline();

            MapPage.mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(minLat, minLng),
                  northeast: LatLng(maxLat, maxLng),
                ),
                100, // Padding
              ),
            );
          },
        );
      }
    }
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

  Widget _builCamera() {
    return Stack(
      children: [
        Positioned(
          left: cameraViewX,
          top: cameraViewY,
          child: GestureDetector(
            onPanUpdate: (details) {
              // Update the position of the camera view based on user drag
              setState(() {
                cameraViewX += details.delta.dx;
                cameraViewY += details.delta.dy;
              });
            },
            child: CameraView().cameraView(context),
          ),
        ),
      ],
    );
  }
}
