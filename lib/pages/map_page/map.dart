// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:audiovision/pages/auth_page/login.dart';
import 'package:audiovision/pages/auth_page/services/auth_services.dart';
import 'package:audiovision/pages/home_page/home.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/pages/map_page/method/polyline_mothod.dart';
import 'package:audiovision/pages/map_page/method/share_location_method.dart';
import 'package:audiovision/pages/map_page/widget/button_start.dart';
import 'package:audiovision/pages/map_page/widget/camera_view.dart';
import 'package:audiovision/pages/map_page/widget/google_map.dart';
import 'package:audiovision/pages/map_page/widget/navigate_bar.dart';
import 'package:audiovision/services/firebase_realtime.dart';
import 'package:audiovision/services/location_services.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
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
  String navigationText = "Continnue";

  double cameraViewX = 0; // Persistent X position
  double cameraViewY = 0; // Persistent Y position
  void updateUi(newPolylines) {
    PolylineId id = const PolylineId("poly");
    setState(() => MapPage.polylines[id] = newPolylines);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Firebase.initializeApp();

    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    googlePlace = GooglePlace(apiKey);

    endFocusNode = FocusNode();

    listenToUserLocation(locationService);
    ShareLocation.dbRef = FirebaseDatabase.instance.ref();

    isLogin();

    //_checkDeviceOrientation();
  }

  @override
  void dispose() {
    locationService.dispose();
    //_gyroscopeStreamSubscription.cancel();
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

  // Function to calculate total distance and total duration
  Map<String, dynamic> _calculateTotals(List<dynamic> steps) {
    double totalDistance = 0.0;
    int totalDuration = 0;

    for (var step in steps) {
      totalDistance += double.parse(step['distance'].split(' ')[0]);
      totalDuration += int.parse(step['duration'].split(' ')[0]);
    }

    // Convert total distance from meters to kilometers
    totalDistance /= 1000;

    return {'totalDistance': totalDistance, 'totalDuration': totalDuration};
  }

  void _showBottomSheet(BuildContext context) {
    Map<String, dynamic> totals = _calculateTotals(MapPage.allSteps);

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double initialHeight = 0.2; // 20% initial height
    double currentHeight = initialHeight;
    DateTime now = DateTime.now();
    int totalDurationMinutes = totals['totalDuration'];
    DateTime expectedArrivalTime =
        now.add(Duration(minutes: totalDurationMinutes));
    showModalBottomSheet(
      elevation: 1,
      backgroundColor: Color.fromARGB(255, 236, 5, 5),
      barrierColor: const Color.fromARGB(17, 0, 0, 0),
      isDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return GestureDetector(
              onVerticalDragUpdate: (details) {
                // Calculate drag direction
                double dy = details.primaryDelta!;
                bool isDraggingUpwards = dy < 0;

                // Clamp between 20% and 60%
                if (isDraggingUpwards) {
                  setState(() {
                    currentHeight = 0.6;
                  });
                } else {
                  setState(() {
                    currentHeight = 0.2;
                  });
                }
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300), // Adjust animation speed
                width: screenWidth * 0.97, // Set width to 95% of screen width
                height: screenHeight * currentHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${totals['totalDuration']} mins ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${totals['totalDistance'].toStringAsFixed(2)} km . ${expectedArrivalTime.hour.toString().padLeft(2, '0')}.${expectedArrivalTime.minute.toString().padLeft(2, '0')} ',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                  onPressed: () {
                                    shareLocation();
                                  },
                                  child: Icon(Icons.share)),
                              SizedBox(
                                width: 5,
                              ),
                              ElevatedButton(
                                  onPressed: () {
                                    MapPage.isStartNavigate = false;
                                    Navigator.of(context)
                                        .pop(); // Close the bottom sheet
                                  },
                                  child: Text("Exit"))
                            ],
                          )
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: MapPage.allSteps.length,
                        itemBuilder: (context, index) {
                          var step = MapPage.allSteps[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            title: Text(
                              step['instructions'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${step['distance']} - ${step['duration']}',
                              style: TextStyle(color: Colors.grey),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                MapPage.isStartNavigate
                    ? Container()
                    : ShareLocation.isTracking
                        ? Container()
                        : build_SearchBar(context),
                destination != null
                    ? ButtonStartNavigateWidget(
                        mapController: MapPage.mapController!,
                        callback: _showBottomSheet,
                        context: context,
                      )
                    : Container(),
                MapPage.isStartNavigate
                    ? NavigateBarWidget(navigationText: navigationText)
                    : Container(),
                // MapPage.isStartNavigate ? builCamera() : Container(),
                // isStartNavigate
                // ? Align(
                //     alignment: Alignment.centerRight, child: cameraView())
                // : Container()

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          // Your map widgets...
                        ],
                      ),
                    ),
                    // Button to show bottom sheet

                    MapPage.isStartNavigate
                        ? ElevatedButton(
                            onPressed: () {},
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 10),
                                Text('Share Location',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          )
                        : ShareLocation.isTracking
                            ? ElevatedButton(
                                onPressed: () {
                                  // Show confirmation dialog to stop tracking
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Stop Tracking"),
                                        content: Text(
                                            "Are you sure you want to stop tracking?"),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text("Cancel"),
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
                                            },
                                          ),
                                          TextButton(
                                            child: Text("Stop"),
                                            onPressed: () {
                                              // stop tracking

                                              ShareLocation.stopTracking();

                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text('Stop Tracking'),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  TextEditingController _userIdController =
                                      TextEditingController();
                                  // Show a dialog to input user ID
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Enter User ID'),
                                        content: TextField(
                                          controller: _userIdController,
                                          decoration: InputDecoration(
                                            hintText: 'Enter User ID',
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
                                            },
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              // Get the entered user ID
                                              String userId = _userIdController
                                                  .text
                                                  .trim(); // Trim any leading/trailing spaces

                                              // Check if the entered user ID is empty
                                              if (userId.isEmpty) {
                                                TextToSpeech.speak(
                                                    "Please enter a User ID.");
                                                // Show an error message indicating that the User ID cannot be empty
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Please enter a User ID.'),
                                                ));
                                                return; // Return without further action
                                              }

                                              // Perform actions with the entered user ID
                                              print('User ID entered: $userId');
                                              ShareLocation.trackingId = userId;
                                              ShareLocation
                                                  .getOtherUserLocation();

                                              // Close the dialog
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 10),
                                    Text('Tracking Location',
                                        style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Search Bar Widget <- SHOULD MOVE TO ANOTHER FILE
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

// add destination when user clck the listview <- SHOULD MOVE TO ANOTHER FILE
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

            PolylineMethod(updateUi).getPolyline(
              LatLng(MapPage.userLatitude, MapPage.userLongitude),
              MapPage.destinationCoordinate,
            );

            MapPage.mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(minLat, minLng),
                  northeast: LatLng(maxLat, maxLng),
                ),
                100, // Padding
              ),
            );

            NavigateMethod().getDirection(
              LatLng(
                MapPage.userLatitude,
                MapPage.userLongitude,
              ),
              LatLng(
                MapPage.destinationCoordinate.latitude,
                MapPage.destinationCoordinate.longitude,
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
        if (MapPage.mapController != null) {
          MapPage.mapController!
              .animateCamera(CameraUpdate.scrollBy(0, _heading));
        }
        print(_heading);
      });
    });
  }

  Widget builCamera() {
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

  void listenToUserLocation(
    LocationService locationService,
  ) {
    // final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

    // always listen to the user position and update it
    locationService.locationStream.listen((userLocation) {
      MapPage.userLatitude = userLocation.latitude;
      MapPage.userLongitude = userLocation.longitude;
      MapPage.cameraPosition = CameraPosition(
        target: LatLng(
          userLocation.latitude,
          userLocation.longitude,
        ),
      );
      updateUserMarkerPosition(
          LatLng(MapPage.userLatitude, MapPage.userLongitude));

      // if tracking user take the value from firebase
      if (ShareLocation.isTracking) {
        ShareLocation.getOtherUserLocation();

        updateUserTrackingMarkerPosition();
      }

      if (ShareLocation.isShared) {
        ShareLocation.updateUserLocation(
            LatLng(MapPage.userLatitude, MapPage.userLongitude));
      }

      // WRRITE DATA IN REALTIME DATABASE
      // updateLocationData(CurrentLocationData(
      //   name: 'John',
      //   coordinates: [
      //     Coordinate(
      //       latitude: userLocation.latitude,
      //       longitude: userLocation.longitude,
      //       timestamp: DateTime.now(),
      //     ),
      //   ],
      // ));

      routeGuidance();
    });
  }

  // update the user marker  position
  void updateUserMarkerPosition(
    LatLng newPosition,
  ) {
    MapPage.cameraPosition = CameraPosition(target: newPosition, zoom: 16.5);

    // Update marker for user's position or add it if not present
    MapPage.markers.removeWhere((marker) => marker.markerId.value == "You");
    MapPage.markers.add(
      Marker(
        markerId: const MarkerId("You"),
        position: newPosition,
        // Custom marker icon
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue), // For example, you can use a blue marker
      ),
    );
    setState(() {});
    if (MapPage.isStartNavigate) {
      PolylineMethod(updateUi!).getPolyline(
        LatLng(MapPage.userLatitude, MapPage.userLongitude),
        MapPage.destinationCoordinate,
      );
    }
  }

  updateUserTrackingMarkerPosition() {
    // Check if trackingUserName is not null
    if (ShareLocation.isTracking) {
      // Update marker for user's position or add it if not present
      final markerToRemove = MapPage.markers.firstWhere(
        (marker) => marker.markerId.value == ShareLocation.trackingUserName!,
        orElse: () => Marker(markerId: MarkerId('default_marker')),
      );

      if (markerToRemove.markerId.value == ShareLocation.trackingUserName!) {
        MapPage.markers.remove(markerToRemove);
      }
      MapPage.markers.add(
        Marker(
          markerId: MarkerId(
              ShareLocation.trackingUserName!), // Assert non-null using !
          position: LatLng(ShareLocation.trackUserCoordinate!.latitude,
              ShareLocation.trackUserCoordinate!.longitude),
          // Custom marker icon
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueCyan,
          ), // For example, you can use a blue marker
        ),
      );
      PolylineMethod(updateUi).getPolyline(
          LatLng(
            ShareLocation.trackUserCoordinate!.latitude,
            ShareLocation.trackUserCoordinate!.longitude,
          ),
          LatLng(
            ShareLocation.trackDestinationCoordinate!.latitude,
            ShareLocation.trackDestinationCoordinate!.longitude,
          ));

      setState(() {});
    }
  }

  void routeGuidance() async {
    String maneuver = "";
    if (MapPage.isStartNavigate) {
      if (stepIndex < MapPage.allSteps.length) {
        print(stepIndex);
        double distanceToStep = await calculateDistance(
          MapPage.userLatitude,
          MapPage.userLongitude,
          MapPage.allSteps[stepIndex]['end_lat'],
          MapPage.allSteps[stepIndex]['end_long'],
        );

        int roundedDistance = distanceToStep.ceil();

        // Assuming there's a threshold distance to trigger the notification
        double thresholdDistance = 100; // meters
        print("WOYYYYYYYYYYYYYYYYYYYYYYYY");
        print(MapPage.allSteps);
        print(distanceToStep);
        if (distanceToStep <= thresholdDistance) {
          maneuver = MapPage.allSteps[stepIndex]['maneuver'] ??
              'Continue'; // Default to 'Continue' if maneuver is not provided
          print("MASIHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH");
          print("In $roundedDistance metersss $maneuver");
          TextToSpeech.speak("In $roundedDistance meters $maneuver");
          stepIndex++;
        } else {
          maneuver = "Continue Straight";
        }

        setState(() {
          navigationText = maneuver;
        });
      }
      double userAndDestinationDistance = await calculateDistance(
        MapPage.userLatitude,
        MapPage.userLongitude,
        MapPage.destinationCoordinate.latitude,
        MapPage.destinationCoordinate.longitude,
      );
      print(userAndDestinationDistance);

      if (userAndDestinationDistance <= 30) {
        setState(() {
          MapPage.isStartNavigate = false;
          print(
              "CONGRATULATIONSSSSSSSSSSSSSSSS YOU HAVE REACEHED THE DESTINATION");
          print("CONGRATULATIONS, YOU HAVE REACEHED THE DESTINATION");
          stepIndex = 0;
          MapPage.markers
              .removeWhere((marker) => marker.markerId.value == "planceName");
        });
      }
    }
  }

  Future<double> calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) async {
    print(startLatitude);
    print(startLongitude);
    double distanceInMeters = await Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return distanceInMeters;
  }

  void isLogin() async {
    await AuthService.isAuthenticated();
  }

  void shareLocation() {
    if (!AuthService.isAuthenticate) {
      Get.to(LoginPage());
      TextToSpeech.speak(
          "You are not logged in. To share your location, you must log in first.");
      return;
    }
    TextToSpeech.speak(
        'Do you want to share your location?. To share your location, Share your ID to other people. your ID is ${AuthService.userId.toString().split("")}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share Location?'),
          content: Text(
              'Do you want to share your location? To share your location, Share your ID to other people. your ID is ${AuthService.userId}'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                    false); // Return false indicating user doesn't want to share location
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                    true); // Return true indicating user wants to share location
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value == true) {
        ShareLocation.shareUserLocation(
          LatLng(MapPage.userLatitude, MapPage.userLongitude),
          MapPage.destinationCoordinate,
        );
      }
    });
  }
}
