import 'dart:async';

import 'package:audiovision/screens/map_screen.dart';
import 'package:audiovision/services/location_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';

class SelectScreen extends StatefulWidget {
  const SelectScreen({super.key});

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  final _startSearchFieldController = TextEditingController();
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS_AKHA'].toString();
    googlePlace = GooglePlace(apiKey);

    startFocusNode = FocusNode();
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
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    startFocusNode.dispose();
    endFocusNode.dispose();

    locationService.dispose();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _startSearchFieldController.text =
            '(${position.latitude}, ${position.longitude})';
      });
    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Audio Vision"),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // TextField(
              //   controller: _startSearchFieldController,
              //   autofocus: false,
              //   focusNode: startFocusNode,
              //   style: const TextStyle(fontSize: 24),
              //   decoration: InputDecoration(
              //     hintText: "Starting point",
              //     hintStyle: const TextStyle(
              //         fontWeight: FontWeight.w500, fontSize: 24),
              //     filled: true,
              //     fillColor: Colors.grey[200],
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(40),
              //       borderSide: const BorderSide(
              //         width: 0,
              //         style: BorderStyle.none,
              //       ),
              //     ),
              //     isDense: true, // Added this
              //     contentPadding: const EdgeInsets.all(15),
              //     suffixIcon: _startSearchFieldController.text.isNotEmpty
              //         ? IconButton(
              //             onPressed: () {
              //               setState(() {
              //                 predictions = [];
              //                 _startSearchFieldController.clear();
              //               });
              //             },
              //             icon: const Icon(Icons.clear_outlined),
              //           )
              //         : null,
              //   ),
              //   onChanged: (value) {
              //     if (_debounce?.isActive ?? false) _debounce!.cancel();
              //     _debounce = Timer(const Duration(milliseconds: 1000), () {
              //       if (value.isNotEmpty) {
              //         //places api
              //         autoCompleteSearch(value);
              //       } else {
              //         //clear out the results
              //         setState(() {
              //           predictions = [];
              //           startPosition = null;
              //         });
              //       }
              //     });
              //   },
              // ),
              Text("YOUR CURRENT LOCATION "),
              Text("latitude $latitude"),
              Text("long $longitude"),
              const SizedBox(
                height: 55,
              ),
              TextField(
                controller: _endSearchFieldController,
                autofocus: false,
                focusNode: endFocusNode,
                // enabled: _startSearchFieldController.text.isNotEmpty,
                style: const TextStyle(fontSize: 24),
                decoration: InputDecoration(
                    hintText: "End point",
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
              ListView.builder(
                  shrinkWrap: true,
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
                      // onTap: () async {
                      //   final placeId = predictions[index].placeId!;
                      //   final details = await googlePlace.details.get(placeId);
                      //   if (details != null &&
                      //       details.result != null &&
                      //       mounted) {
                      //     if (startFocusNode.hasFocus) {
                      //       setState(() {
                      //         startPosition = details.result;
                      //         _startSearchFieldController.text =
                      //             details.result!.name!;
                      //         predictions = [];
                      //       });
                      //     } else {
                      //       setState(() {
                      //         endPosition = details.result;
                      //         _endSearchFieldController.text =
                      //             details.result!.name!;
                      //         predictions = [];
                      //       });
                      //     }
                      //     if (startPosition != null && endPosition != null) {
                      //       print("Navigate");
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (context) => MapScreen(
                      //               startPosition: startPosition,
                      //               endPosition: endPosition),
                      //         ),
                      //       );
                      //     }
                      //   }
                      // },
                      onTap: () async {
                        final placeId = predictions[index].placeId!;
                        final details = await googlePlace.details.get(placeId);
                        if (details != null &&
                            details.result != null &&
                            mounted) {
                          if (startFocusNode.hasFocus) {
                            setState(() {
                              startPosition = details.result;
                              _startSearchFieldController.text =
                                  details.result!.name!;
                              predictions = [];
                            });
                          } else {
                            setState(() {
                              endPosition = details.result;
                              _endSearchFieldController.text =
                                  details.result!.name!;
                              predictions = [];
                            });
                          }

                          print("Start Position: $startPosition");
                          print("End Position: $endPosition");

                          // Check if both start and end positions are set
                          if (startPosition != null && endPosition != null) {
                            print("Navigate");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapScreen(
                                    startPosition: startPosition,
                                    endPosition: endPosition),
                              ),
                            );
                          } else {
                            print("Both positions are not set yet");
                          }
                        }
                      },
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
