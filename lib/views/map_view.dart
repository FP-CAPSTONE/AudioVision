import 'dart:async';

import 'package:audiovision/services/location_services.dart';
import 'package:audiovision/services/user_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  Set<Marker> userMarker = {};
  CameraPosition cameraPosition = CameraPosition(
    target: LatLng(
      latitude,
      longitude,
    ),
  );

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
    return GestureDetector(
      onDoubleTap: () {},
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 100,
            ),
            Text("YOUR CURRENT LOCATION "),
            Text("latitude $latitude"),
            Text("long $longitude"),
            TextField(
              controller: _endSearchFieldController,
              autofocus: false,
              focusNode: endFocusNode,
              // enabled: _startSearchFieldController.text.isNotEmpty,
              style: const TextStyle(fontSize: 24),
              decoration: InputDecoration(
                  hintText: "Search Here",
                  hintStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 24),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                    borderSide: const BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  isDense: true, // Added this
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
                      : null),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 1000), () {
                  if (value.isNotEmpty) {
                    //places api
                    autoCompleteSearch(value);
                  } else {
                    //clear out the results
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
                  GestureDetector(
                    onTap: () {},
                    child: GoogleMap(
                      initialCameraPosition: cameraPosition,
                      onMapCreated: (controller) {
                        _controller = controller;
                      },
                      markers: userMarker,
                    ),
                  ),
                  ListView.builder(
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
                              });
                            }
                            print("Start Position: $startPosition");
                            print("End Position: $endPosition");
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateUserLocation(LatLng newPosition) {
    setState(() {
      cameraPosition = CameraPosition(target: newPosition, zoom: 16.5);
      userMarker = {
        Marker(
          markerId: const MarkerId("You"),
          position: newPosition,
        )
      };
    });
    _controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }
}
