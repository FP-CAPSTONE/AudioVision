// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:audiovision/controller/scan_controller.dart';
import 'package:audiovision/pages/map_page/method/marker_method.dart';
import 'package:audiovision/pages/map_page/widget/bottom_sheet_near_location.dart';
import 'package:audiovision/pages/map_page/widget/buttom_sheet_detail_ocation.dart';
import 'package:audiovision/pages/map_page/method/searching_method.dart';
import 'package:audiovision/pages/map_page/widget/panel_widget.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:audiovision/pages/auth_page/login.dart';
import 'package:audiovision/pages/auth_page/services/auth_services.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/pages/map_page/method/polyline_mothod.dart';
import 'package:audiovision/pages/map_page/method/share_location_method.dart';
import 'package:audiovision/pages/map_page/widget/bottom_sheet.dart';
import 'package:audiovision/pages/map_page/widget/camera_view.dart';
import 'package:audiovision/pages/map_page/widget/google_map.dart';
import 'package:audiovision/pages/map_page/widget/navigate_bar.dart';
import 'package:audiovision/services/location_services.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_compass/flutter_compass.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
// ned to change the class name, there are two location service
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:vibration/vibration.dart';
import '../setting_page/setting.dart';

class MapPage extends StatefulWidget {
  static bool canNotify = true;

  static var panelController = PanelController();
  static double panelHeightClosed = 0.0;
  static double panelHeightOpen = 0.0;

  static String nearLocationAddress = '';

  static NearBySearchResponse? nearbyLocationResponse;
  findNearbyLocation() async {
    try {
      String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS_AKHA'].toString();
      // String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString(); // udah gabisa
      GooglePlace googlePlace = GooglePlace(apiKey);
      var result = await googlePlace.search
          .getNearBySearch(
            Location(lat: userLatitude, lng: userLongitude),
            1500,
            language: MapPage.isIndonesianSelected ? "id" : "en",
          )
          .timeout(const Duration(seconds: 50)); // Increase timeout duration
      if (result != null) {
        for (var i = 1; i < 5; i++) {
          // result.results[0].formattedAddress; // get place address name
          String placeId = result!.results![i].placeId ?? "Null";

          final details = await googlePlace.details.get(placeId);
          if (details?.result != null) {
            nearbyLocationDetails.add({
              "lat": details!.result!.geometry!.location!.lat!,
              "long": details.result!.geometry!.location!.lng!,
              "placeId": placeId,
              "placeName": details.result!.name
            });
          }
        }
      }
      nearbyLocationResponse = result;
      Map detailNearby = MapPage.nearbyLocationDetails[1];

      MapPage.markers.removeWhere(
          (marker) => marker.markerId.value == detailNearby['placeId']);
      final Uint8List markerIcon = await MarkerMethod.getBytesFromAsset(
          'assets/markers/destination_fill.png', 100);
      MapPage.markers.add(
        Marker(
          markerId: const MarkerId("planceName"),
          position: LatLng(detailNearby['lat'], detailNearby['long']),
          icon: BitmapDescriptor.fromBytes(markerIcon),
          infoWindow: InfoWindow(
            title: detailNearby['placeName'],
          ),
        ),
      );

      // find the north and south to animate the camera
      double minLat = MapPage.userLatitude < detailNearby['lat']
          ? MapPage.userLatitude
          : detailNearby['lat'];
      double minLng = MapPage.userLongitude < detailNearby['long']
          ? MapPage.userLongitude
          : detailNearby['long'];
      double maxLat = MapPage.userLatitude > detailNearby['lat']
          ? MapPage.userLatitude
          : detailNearby['lat'];
      double maxLng = MapPage.userLongitude > detailNearby['long']
          ? MapPage.userLongitude
          : detailNearby['long'];

      MapPage.mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100, // Padding
        ),
      );
      BottomSheetNearLocation.destinationPlaceId = detailNearby['placeId'];
      print("nearby location ${result!.results![0].name}");
      return result;
    } catch (e) {
      print("Error: $e");
    }
  }

  static List nearbyLocationDetails = [];

  //public variable
  static double userLatitude = 0;
  static double userLongitude = 0;
  static LatLng userPreviousCoordinate = const LatLng(0, 0);

  static LatLng destinationCoordinate = const LatLng(0, 0);

  static bool isStartNavigate = false;

  static bool isIndonesianSelected = false;

  static GoogleMapController? mapController;

  static List<dynamic> allSteps = [];
  static Map<String, dynamic> endLocation = {};

  static Map googleMapDetail = {
    "name": "",
    "rating": 0.0,
    "ratingTotal": 5,
    "type": [],
    "openingHours": "",
    "photoReference": [],
  };
  static CameraPosition cameraPosition = CameraPosition(
    target: LatLng(
      userLatitude,
      userLongitude,
    ),
  );

  static Map<PolylineId, Polyline> polylines = {};

  static Set<Marker> markers = {};

  static int totalDurationToDestination = 0;
  static double total_distance = 0.0;
  static int total_duration = 0;
  static String destinationLocationName = "";

  static double compassHeading = 0;
  static int distance = 0;

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

  int stepIndex = 0;
  String navigationText = "";
  String distanceToNextStep = "";

  double cameraViewX = 0; // Persistent X position
  double cameraViewY = 0; // Persistent Y position
  void updateUi(newPolylines) {
    PolylineId id = const PolylineId("poly");
    setState(() => MapPage.polylines[id] = newPolylines);
  }

  String mapTheme = "";
  bool fromAudioCommand = false;

  Map<String, String> searchLogs = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Firebase.initializeApp();

    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS_AKHA'].toString();
    // String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString(); // udah gabisa
    googlePlace = GooglePlace(apiKey);

    endFocusNode = FocusNode();

    listenToUserLocation(locationService);
    ShareLocation.dbRef = FirebaseDatabase.instance.ref();
    _loadSelectedLanguage();
    isLogin();
    print("init");
    _initCompass();
    // Future.delayed(const Duration(seconds: 2), () {
    //   const MapPage().findNearbyLocation();
    // });

    DefaultAssetBundle.of(context)
        .loadString("assets/maptheme/custom_map.json")
        // .loadString("assets/maptheme/night_map.json")
        .then((value) {
      mapTheme = value;
    });
    //_checkDeviceOrientation();+
  }

  Future<void> _loadSelectedLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      MapPage.isIndonesianSelected =
          prefs.getBool('isIndonesianSelected') ?? false;
      // _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    });
  }

  Future<void> _saveSetting() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isIndonesianSelected', MapPage.isIndonesianSelected);
    // await prefs.setDouble('fontSize', _fontSize);
  }

  // Initialize compass and start listening to updates
  void _initCompass() {
    print("init");
    FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        double compassHeading = event.heading ?? 0;
        double compareCurentRotation =
            (compassHeading - MapPage.compassHeading).abs();

        // Check if the difference between the current compass heading and the previous heading is greater than 10 degrees
        if (compareCurentRotation > 15) {
          MapPage.compassHeading = compassHeading;

          // Update marker and camera rotation only when the rotation of the compass > 10 degrees
          MarkerMethod.updateMarkerAndCameraRotation();
          print("compas $compassHeading");
          // Determine cardinal direction based on compass heading
          String direction = _getCardinalDirection(compassHeading);
          print("Current direction: $direction");
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 1000), () {
            // stop listening
            if (MapPage.isStartNavigate) {
              TextToSpeech.speak("Your current direction is $direction");
            }
          });
        }
      });
    });
  }

  String _getCardinalDirection(double compassHeading) {
    print("compas $compassHeading");

    // Define cardinal directions
    List<String> directions = MapPage.isIndonesianSelected
        ? [
            'Utara',
            'Timur Laut',
            'Timur',
            'Tenggara',
            'selatan',
            'barat daya',
            'Barat',
            'Barat Laut'
          ]
        : [
            'North',
            'Northeast',
            'East',
            'Southeast',
            'South',
            'Southwest',
            'West',
            'Northwest'
          ];

    // Calculate index based on compass heading
    int index = ((compassHeading % 360) / 45).round();

    // Return the corresponding cardinal direction
    return directions[index % 8];

    // TODO : comapre the the direction with all steps from directons apiS
  }

  @override
  void dispose() {
    locationService.dispose();
    //_gyroscopeStreamSubscription.cancel();
    super.dispose();
  }

  void autoCompleteSearch(String value) async {
    try {
      if (value != "") {
        var result = await googlePlace.autocomplete.get(value,
            language: MapPage.isIndonesianSelected ? "id" : "en",
            // language: MapPage.isIndonesianSelected ? "en" : "id",
            origin: LatLon(MapPage.userLatitude, MapPage.userLongitude));

        if (result != null && result.predictions != null && mounted) {
          setState(() {
            predictions = result.predictions!;
            print(predictions);
            if (predictions.isNotEmpty && fromAudioCommand == true) {
              SearchMethod.save_search_log(
                  predictions[0].description.toString(),
                  predictions[0].placeId.toString());

              TextToSpeech.speak(
                  "set destination to ${predictions[0].description}. double tap the screen. and. say Start navigate. to start navigation");
              addDestination(predictions[0].placeId.toString());
              fromAudioCommand = false;
              _endSearchFieldController.text = "";
              return;
            }
            TextToSpeech.speak("Hold the screen to read the search result");
          });
        }
      } else {
        TextToSpeech.speak("where you want to go?");
      }
    } on TimeoutException catch (e) {
      print("TimeoutException: $e");
      // Handle timeout gracefully, such as showing a message to the user
    } catch (e) {
      print("Error: $e");
      // Handle other exceptions if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        defaultPanelState: PanelState.CLOSED,
        controller: MapPage.panelController,
        minHeight: MapPage.panelHeightClosed,
        maxHeight: MapPage.panelHeightOpen,
        body: GestureDetector(
          onDoubleTap: () {
            MapPage.canNotify = false;

            TextToSpeech.speak("Audio command activated, say something");
            _isListening = false;
            _text = '';
            Vibration.vibrate();

            Timer(Duration(seconds: MapPage.isIndonesianSelected ? 5 : 3), () {
              audioCommand();
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GestureDetector(
                      onLongPress: () {
                        TextToSpeech.speak(
                            "this is a maps. double tap the screen to activate audio command");
                      },
                      child: GoogleMapWidget(
                        mapstyle: mapTheme,
                      ),
                    ),
                    MapPage.isStartNavigate
                        ? Container()
                        : ShareLocation.isTracking
                            ? Container()
                            : build_SearchBar(context),
                    // destination != null
                    //     ? ButtonStartNavigateWidget(
                    //         mapController: MapPage.mapController!,
                    //         context: context,
                    //       )
                    //     : Container(),
                    MapPage.isStartNavigate
                        ? NavigateBarWidget(
                            navigationText: navigationText,
                            distance: distanceToNextStep,
                            manuever: maneuver,
                            instruction: instruction,
                          )
                        : Container(),
                    Center(
                      child: _isListening
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // SizedBox(
                                //     height: MediaQuery.of(context).size.height *
                                //         0.), // Adjust the height as needed
                                AvatarGlow(
                                  animate: true,
                                  glowColor: Colors.grey,
                                  duration: const Duration(milliseconds: 1000),
                                  glowCount: 2,
                                  // glowRadiusFactor: 0.7,
                                  child: const Icon(
                                    Icons.mic,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(
                                    height:
                                        10), // Add some spacing between the icon and text
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .grey, // Set your desired background color here
                                    borderRadius: BorderRadius.circular(
                                        8), // Optional: Add border radius to make it rounded
                                  ),
                                  padding: const EdgeInsets.all(
                                      8), // Optional: Add padding around the text
                                  child: Text(
                                    _text,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors
                                            .white), // Set text color if needed
                                  ),
                                )
                              ],
                            )
                          : const SizedBox(),
                    ),
                    ShareLocation.isTracking
                        ? Container()
                        : MapPage.isStartNavigate
                            ? CustomBottomSheet(
                                shareLocationCallback: shareLocation,
                              )
                            : !MapPage.isStartNavigate &&
                                    MapPage.destinationCoordinate.latitude != 0
                                ? const BottomSheetDetailLocation()
                                : BottomSheetNearLocation(addDestination),
                    // NavigateBarWidget(
                    //   navigationText: "navigationText",
                    //   distance: "20 m",
                    //   manuever: "turn-left",
                    // ),
                    MapPage.isStartNavigate ? builCamera() : Container(),
                    // isStartNavigate
                    // ? Align(
                    //     alignment: Alignment.centerRight, child: cameraView())
                    // : Container(),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Stack(
                            children: [
                              // Your map widgets...
                            ],
                          ),
                        ),
                        // Button to show bottom sheet

                        MapPage.isStartNavigate
                            ? Container()
                            : ShareLocation.isTracking
                                ? ElevatedButton(
                                    onPressed: () {
                                      // Show confirmation dialog to stop tracking
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Stop Tracking"),
                                            content: const Text(
                                                "Are you sure you want to stop tracking?"),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text("Cancel"),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(); // trackClose the dialog
                                                },
                                              ),
                                              TextButton(
                                                child: const Text("Stop"),
                                                onPressed: () {
                                                  // stop tracking
                                                  ShareLocation.stopTracking();
                                                  MapPage.panelController
                                                      .close();
                                                  MapPage.panelController
                                                      .hide();
                                                  print("stop tracking");

                                                  Navigator.of(context)
                                                      .pop(); // Close the dialog
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: const Text('Stop Tracking'),
                                  )
                                : MapPage.destinationCoordinate.latitude == 0
                                    ? GestureDetector(
                                        onLongPress: () {
                                          TextToSpeech.speak("Track Button");
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(
                                              bottom: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.0 +
                                                  2),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(200),
                                            color: const Color.fromARGB(
                                                255, 163, 71, 71),
                                          ),
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.065,
                                          child: Material(
                                            // Wrap ElevatedButton with Material
                                            borderRadius: BorderRadius.circular(
                                                50), // Apply the same border radius
                                            color: const Color.fromARGB(255, 0,
                                                0, 0), // Apply the same color
                                            child: InkWell(
                                              // Wrap ElevatedButton with InkWell for ripple effect
                                              borderRadius: BorderRadius.circular(
                                                  8), // Apply the same border radius
                                              onTap: () {
                                                TextToSpeech.speak(
                                                    "clicking track button, enter a username to track other user ");
                                                TextEditingController
                                                    userNameController =
                                                    TextEditingController();
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                        MapPage.isIndonesianSelected
                                                            ? 'Lacak Lokasi'
                                                            : 'Track Location',
                                                        style: TextStyle(
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.034),
                                                      ),
                                                      content: TextField(
                                                        controller:
                                                            userNameController,
                                                        decoration:
                                                            const InputDecoration(
                                                          hintText:
                                                              'Enter Username',
                                                        ),
                                                      ),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            String userName =
                                                                userNameController
                                                                    .text
                                                                    .trim();
                                                            if (userName
                                                                .isEmpty) {
                                                              // Handle empty email
                                                              TextToSpeech.speak(
                                                                  "Please enter the user name.");
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                      'Please enter the Username.'),
                                                                ),
                                                              );
                                                              return;
                                                            }

                                                            // Perform actions with the entered user ID                                                                .getOtherUserLocation();
                                                            // Close the dialog
                                                            MapPage
                                                                .panelController
                                                                .open();

                                                            print(
                                                                'User ID entered: $userName');
                                                            ShareLocation
                                                                .checkOtherUser(
                                                                    userName,
                                                                    context);

                                                            // setState(() {});
                                                          },
                                                          child: const Text(
                                                              'Track'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal:
                                                        10), // Adjust padding to match the original design
                                                child: Center(
                                                  child: Text(
                                                    MapPage.isIndonesianSelected
                                                        ? 'Lacak Lokasi'
                                                        : 'Track Lcation',
                                                    style: TextStyle(
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.05,
                                                      color: Colors
                                                          .white, // Set text color to white
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        panelBuilder: (controller) => PanelWidget(
          controller: controller,
          panelController: MapPage.panelController,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
    );
  }

  //Searchbar with advance UI and wrapped in container
  Widget build_SearchBar(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 40, // Set the height of the container
          decoration: BoxDecoration(
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Padding(
            padding:
                const EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPress: () {
                      TextToSpeech.speak("Search bar");
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _endSearchFieldController,
                        autofocus: false,
                        focusNode: endFocusNode,
                        style: TextStyle(
                            fontSize:
                                MediaQuery.of(context).size.width * 0.057),
                        decoration: InputDecoration(
                          hintText: MapPage.isIndonesianSelected
                              ? "Cari Disini"
                              : "Search Here",
                          hintStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.057),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.all(15),
                          prefixIcon: _endSearchFieldController
                                      .text.isNotEmpty ||
                                  searchLogs.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      predictions = [];
                                      _endSearchFieldController.clear();
                                      searchLogs = {};
                                      MapPage.destinationCoordinate =
                                          const LatLng(
                                        0,
                                        0,
                                      );
                                      PolylineMethod(callbackSetState)
                                          .clearPolyline();
                                      const MapPage().findNearbyLocation();
                                    });
                                  },
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_outlined,
                                    size: MediaQuery.of(context).size.width *
                                        0.06,
                                  ),
                                )
                              : Icon(
                                  Icons.search,
                                  size:
                                      MediaQuery.of(context).size.width * 0.08,
                                ),
                          // suffixIcon: _endSearchFieldController.text.isNotEmpty
                          //     ? IconButton(
                          //         onPressed: () {
                          //           setState(() {
                          //             predictions = [];
                          //             _endSearchFieldController.clear();
                          //           });
                          //         },
                          //         icon: const Icon(Icons.clear_outlined),
                          //       )
                          //     : null,
                        ),
                        onChanged: (value) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 1000), () {
                            if (value.isNotEmpty) {
                              fromAudioCommand = false;
                              autoCompleteSearch(value);
                            } else {
                              setState(() {
                                predictions = [];
                                destination = null;
                              });
                            }
                          });
                        },
                        onTap: () async {
                          TextToSpeech.speak(
                              "Clicking search bar. search where you want to go. and hold the screen to read the search result. or. you can double tap the screen to activate the audio command. say.   'navigate destination' or 'going destination' to set your destination");
                          searchLogs = await SearchMethod.getSearchLogs();
                          // Iterate through the search logs
                          searchLogs.forEach((log, placeId) {
                            print("Search Log: $log, Place ID: $placeId");
                            // Here you can perform any desired actions with the search log and place ID
                          });
                          print("search log $searchLogs");
                          // Iterate through the search logs
                          searchLogs.forEach((log, placeId) {
                            print("Search Log: $log, Place ID: $placeId");
                            // Here you can perform any desired actions with the search log and place ID
                          });
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Get.to(() => const SettingPage());
                    // Add your settings icon onPressed logic here
                  },
                  icon: const Icon(Icons.settings),
                  color: const Color.fromARGB(255, 212, 212, 212),
                  iconSize: MediaQuery.of(context).size.width * 0.1,
                ),
              ],
            ),
          ),
        ),
        if (predictions.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: predictions.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onLongPress: () {
                    print("res${predictions[index].description}");
                    TextToSpeech.speak(
                        predictions[index].description.toString());
                  },
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.15,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.black,
                                    ),
                                    if (predictions[index].distanceMeters !=
                                        null)
                                      buildDistanceWidget(
                                          predictions[index].distanceMeters!)
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      predictions[index]
                                          .terms!
                                          .first
                                          .value
                                          .toString(),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04),
                                    ),
                                    if (predictions[index].terms != null &&
                                        predictions[index].terms!.length > 1)
                                      Text(
                                        predictions[index]
                                            .terms![1]
                                            .value
                                            .toString(),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03, // Adjust the multiplier as needed
                                          color: Colors.grey[600],
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Call this function where you want to save the search log
                          onTap: () async {
                            TextToSpeech.speak(
                                "set destination to ${predictions[index].description}. double tap the screen. and. say Start navigate. to start navigation");
                            await SearchMethod.save_search_log(
                              predictions[index].terms!.first.value.toString(),
                              predictions[index].placeId.toString(),
                            );
                            addDestination(
                              predictions[index].placeId.toString(),
                            );
                          },
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.grey.withOpacity(0.5),
                      ), // Add this line to include a separator
                    ],
                  ),
                );
              },
            ),
          ),
        if (searchLogs.isNotEmpty && _endSearchFieldController.text == "")
          Container(
            color: Colors.white,
            width: MediaQuery.of(context).size.width * 1,
            child: Padding(
              padding: const EdgeInsets.only(
                  right: 10, left: 25, top: 10, bottom: 0),
              child: Text(
                "Recent",
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width *
                        0.034, // Adjust the font size as needed

                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (searchLogs.isNotEmpty && _endSearchFieldController.text == "")
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: searchLogs.length,
              itemBuilder: (context, index) {
                // Get the key and value from the searchLogs map
                String log = searchLogs.keys.toList()[index];
                List arrayLog = searchLogs.keys.toList()[index].split(",");
                String placeId = searchLogs.values.toList()[index];

                return GestureDetector(
                  onLongPress: () {
                    print("res$log");
                    TextToSpeech.speak(log);
                  },
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.only(
                                    right: MediaQuery.of(context).size.width *
                                        0.03),
                                child: Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.black,
                                  size:
                                      MediaQuery.of(context).size.width * 0.075,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      arrayLog.first,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04),
                                    ),
                                    if (arrayLog.length > 1)
                                      Text(
                                        RegExp(r'\s+(.*)')
                                                .firstMatch(arrayLog[1])
                                                ?.group(1) ??
                                            '', // Take all text after first space
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                          color: Colors.grey[600],
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Call this function where you want to save the search log
                          onTap: () async {
                            TextToSpeech.speak(
                                "set destination to $log. double tap the screen. and. say Start navigate. to start navigation");
                            await SearchMethod.save_search_log(log, placeId);
                            addDestination(placeId);
                          },
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.grey.withOpacity(0.5),
                      ), // Add this line to include a separator
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget buildDistanceWidget(int distanceMeters) {
    if (distanceMeters < 1000) {
      // Display distance in meters format
      return Text(
        "$distanceMeters m",
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      );
    } else if (distanceMeters < 10000) {
      // Convert distance from meters to kilometers and format it as "0.0 km"
      String formattedDistance =
          "${(distanceMeters / 1000.0).toStringAsFixed(1)} km";
      return Text(
        formattedDistance,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      );
    } else {
      // If it's too far, just show the icon
      return const SizedBox.shrink(); // This returns an empty widget
    }
  }

  // DetailsResponse details = DetailsResponse();

// add destination when user clck the listview <- SHOULD MOVE TO ANOTHER FILE
// add destination when user clck the listview <- SHOULD MOVE TO ANOTHER FILE
  void addDestination(String placeId) async {
    MapPage.googleMapDetail['photoReference'] =
        []; // remove all photo in here if any
    final Uint8List markerIcon = await MarkerMethod.getBytesFromAsset(
        'assets/markers/destination_fill.png', 100);

    // getPlaceDetail(placeId);

    final details = await googlePlace.details
        .get(placeId)
        .timeout(const Duration(seconds: 50));
    MapPage.googleMapDetail['name'] = details!.result!.name.toString();
    MapPage.googleMapDetail['rating'] = details.result!.rating;
    MapPage.googleMapDetail['ratingTotal'] = details.result!.userRatingsTotal;
    MapPage.googleMapDetail['types'] = details.result!.types;
    // MapPage.googleMapDetail['openingHours'] =
    //     details.result!.openingHours!.periods;
    if (details.result?.photos != null) {
      for (var photo in details.result!.photos!) {
        String? photoReference = photo.photoReference;
        // Construct the URL using the photo reference
        // String url =
        //     'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=' +
        //         dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
        MapPage.googleMapDetail['photoReference']
            .add(photoReference); // Add URLs to the 'images' list
      }
    }
    print("kontrol${details.result!.name}");
    print("kontrol${details.result!.photos}");
    print("kontrol${details.result!.rating}");
    print("kontrol${details.result!.userRatingsTotal}");
    if (details.result != null && mounted) {
      setState(
        () {
          destination = details.result;
          _endSearchFieldController.text = details.result!.name!;
          print(details.result!);
          print(details.result!);
          MapPage.destinationLocationName = _endSearchFieldController.text;
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
              icon: BitmapDescriptor.fromBytes(markerIcon),
              infoWindow: InfoWindow(
                title: MapPage.destinationLocationName,
              ),
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

  // getPlaceDetail(String placeId) async {
  //   details = (await googlePlace.details.get(placeId))!;
  //   MapPage.googleMapDetail['name'] = details.result!.name.toString();
  //   MapPage.googleMapDetail['rating'] = details.result!.rating;
  //   MapPage.googleMapDetail['ratingTotal'] = details.result!.userRatingsTotal;
  //   MapPage.googleMapDetail['types'] = details.result!.types;
  //   // MapPage.googleMapDetail['openingHours'] =
  //   //     details.result!.openingHours!.periods;
  //   if (details.result?.photos != null) {
  //     for (var photo in details.result!.photos!) {
  //       String? photoReference = photo.photoReference;
  //       // Construct the URL using the photo reference
  //       String url =
  //           'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=' +
  //               dotenv.env['GOOGLE_MAPS_API_KEYS_AKHA'].toString();
  //       MapPage.googleMapDetail['photoReference']
  //           .add(photoReference); // Add URLs to the 'images' list
  //     }
  //   }
  //   print("kontrol" + details.result!.name.toString());
  //   print("kontrol" + details.result!.photos.toString());
  //   print("kontrol" + details.result!.rating.toString());
  //   print("kontrol" + details.result!.userRatingsTotal.toString());
  // }

  // void _checkDeviceOrientation() {
  //   // Store the subscription returned by accelerometerEvents.listen()
  //   _gyroscopeStreamSubscription =
  //       gyroscopeEvents.listen((GyroscopeEvent event) {
  //     setState(() {
  //       // print("x");
  //       // print(event.x * 10.0);
  //       // print("y");
  //       // print(event.y * 10.0);
  //       // print("z");
  //       // print(event.z * 10.0);
  //       _heading = event.z * 10.0;
  //       if (MapPage.mapController != null) {
  //         MapPage.mapController!
  //             .animateCamera(CameraUpdate.scrollBy(0, _heading));
  //       }
  //       print(_heading);
  //     });
  //   });
  // }

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
        ShareLocation.updateUserLocationToFirebase(
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
  ) async {
    final Uint8List userMarker = await MarkerMethod.getBytesFromAsset(
        'assets/markers/user-marker.png', 100);
    MapPage.cameraPosition = CameraPosition(target: newPosition, zoom: 16.5);

    // Update marker for user's position or add it if not present
    MapPage.markers.removeWhere((marker) => marker.markerId.value == "You");
    MapPage.markers.add(
      Marker(
        markerId: const MarkerId("You"),
        position: newPosition,
        // Custom marker icon
        icon: BitmapDescriptor.fromBytes(
            userMarker), // For example, you can use a blue marker
        infoWindow: const InfoWindow(title: "You"),
        rotation: MapPage.compassHeading,

        anchor: const Offset(0.5, 0.5),
      ),
    );

    MapPage.userPreviousCoordinate =
        LatLng(MapPage.userLatitude, MapPage.userLongitude);

    setState(() {});
    if (MapPage.isStartNavigate) {
      PolylineMethod(updateUi).getPolyline(
        LatLng(MapPage.userLatitude, MapPage.userLongitude),
        MapPage.destinationCoordinate,
      );
    } else {
      stepIndex = 0;
    }
  }

  updateUserTrackingMarkerPosition() async {
    final Uint8List userTrackingMarker = await MarkerMethod.getBytesFromAsset(
        'assets/markers/user_track.png', 100);
    // Check if trackingUserName is not null
    if (ShareLocation.isTracking) {
      // Update marker for user's position or add it if not present
      final markerToRemove = MapPage.markers.firstWhere(
        (marker) => marker.markerId.value == ShareLocation.trackingUserName!,
        orElse: () => const Marker(markerId: MarkerId('default_marker')),
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
          icon: BitmapDescriptor.fromBytes(userTrackingMarker),
          infoWindow: InfoWindow(title: ShareLocation.trackingUserName),
          // For example, you can use a blue marker
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

  String maneuver = "Loading..";
  String distance = "Loading..";
  String instruction = "Loading..";

  void routeGuidance() async {
    if (MapPage.isStartNavigate) {
      if (stepIndex < MapPage.allSteps.length) {
        print(stepIndex);

        auditoryGuidance();

        setState(() {
          navigationText = maneuver;
          distanceToNextStep = distance;
          instruction = instruction;
        });
      }
      double userAndDestinationDistance = await calculateDistance(
        MapPage.userLatitude,
        MapPage.userLongitude,
        MapPage.destinationCoordinate.latitude,
        MapPage.destinationCoordinate.longitude,
      );

      if (userAndDestinationDistance <= 30) {
        setState(() {
          MapPage.isStartNavigate = false;
          stepIndex = 0;
          MapPage.markers
              .removeWhere((marker) => marker.markerId.value == "planceName");
          TextToSpeech.speak("Congratulations you have reach your destination");
        });
      }
    }
  }

  auditoryGuidance() async {
    double distanceToStep = await calculateDistance(
      MapPage.userLatitude,
      MapPage.userLongitude,
      MapPage.allSteps[stepIndex]['end_lat'],
      MapPage.allSteps[stepIndex]['end_long'],
    );

    int roundedDistance = distanceToStep.ceil();
    MapPage.distance = roundedDistance;

    // Assuming there's a threshold distance to trigger the notification
    double thresholdDistance = 100; // meters
    double thresholdDistance2 = 50; // meters
    double thresholdDistance3 = 20; // meters
    double thresholdDistance4 = 10; // meters
    double thresholdDistance5 = 5; // meters
    if (MapPage.canNotify) {
      print("canNotify ${MapPage.canNotify}");

      MapPage.canNotify = false;
      if (distanceToStep <= thresholdDistance) {
        maneuver = MapPage.allSteps[stepIndex]['maneuver'] ?? 'Continue';
        instruction = MapPage.allSteps[stepIndex]['instructions'] ?? 'Continue';
        distance = MapPage.allSteps[stepIndex]['distance'] ?? '0 m';
        TextToSpeech.speak("In $roundedDistance meters $instruction");
      } else if (distanceToStep <= thresholdDistance2) {
        maneuver = MapPage.allSteps[stepIndex]['maneuver'] ?? 'Continue';
        instruction = MapPage.allSteps[stepIndex]['instructions'] ?? 'Continue';
        distance = MapPage.allSteps[stepIndex]['distance'] ?? '0 m';
        TextToSpeech.speak("In $roundedDistance meters $instruction");
      } else if (distanceToStep <= thresholdDistance3) {
        maneuver = MapPage.allSteps[stepIndex]['maneuver'] ?? 'Continue';
        instruction = MapPage.allSteps[stepIndex]['instructions'] ?? 'Continue';
        distance = MapPage.allSteps[stepIndex]['distance'] ?? '0 m';
        TextToSpeech.speak("In $roundedDistance meters $instruction");
      } else if (distanceToStep <= thresholdDistance4) {
        maneuver = MapPage.allSteps[stepIndex]['maneuver'] ?? 'Continue';
        instruction = MapPage.allSteps[stepIndex]['instructions'] ?? 'Continue';
        distance = MapPage.allSteps[stepIndex]['distance'] ?? '0 m';
        TextToSpeech.speak("In $roundedDistance meters $instruction");
        stepIndex++;
      } else if (distanceToStep <= thresholdDistance5) {
        maneuver = MapPage.allSteps[stepIndex]['maneuver'] ?? 'Continue';
        instruction = MapPage.allSteps[stepIndex]['instructions'] ?? 'Continue';
        distance = MapPage.allSteps[stepIndex]['distance'] ?? '0 m';
        TextToSpeech.speak("$instruction");
        stepIndex++;
      }
      Future.delayed(const Duration(seconds: 30), () {
        MapPage.canNotify = true;
      });
    }
  }

  Future<double> calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) async {
    double distanceInMeters = Geolocator.distanceBetween(
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

  void shareLocation(BuildContext context) {
    String userName = AuthService.userName.toString();
    // TextToSpeech.speak(
    //     'Do you want to share your location?. To share your location, Share your username to other people. your username is "$userName.split("")" ');
    TextToSpeech.speak(
        'Do you want to share your location?. To share your location, Share your username to other people. your username is "$userName" ');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share Location?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MapPage.isIndonesianSelected
                    ? "Apakah Anda ingin membagikan lokasi Anda? Untuk membagikan lokasi Anda, Bagikan nama pengguna Anda kepada orang lain. nama user Anda adalah $userName"
                    : 'Do you want to share your location? To share your location, Share your username to other people. your username is $userName',
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('No'),
                  ),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     // Copy the user ID to the clipboard
                  //     Clipboard.setData(ClipboardData(text: userName));
                  //     Navigator.of(context).pop(
                  //         true); // Return true indicating user wants to share location
                  //   },
                  //   child: Text('Copy ID'),
                  // ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((value) {
      if (value == true) {
        if (AuthService.isAuthenticate) {
          final String? userName = AuthService.userName;

          TextToSpeech.speak(
              "Start hsaring your location. share your username to other people, your username is $userName");
          ShareLocation.shareUserLocation(
            LatLng(MapPage.userLatitude, MapPage.userLongitude),
            MapPage.destinationCoordinate,
            MapPage.total_distance,
            MapPage.total_duration,
            MapPage.destinationLocationName,
            MapPage.nearLocationAddress,
          );
        } else {
          Get.to(const LoginPage());
          TextToSpeech.speak(
              "You are not logged in. To share your location, you must log in first.");
        }
      }
    });
  }

  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _text = '';

  void audioCommand() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print("Status: $status");
        },
        onError: (errorNotification) {
          print("Error: $errorNotification");
        },

        // Specify the desired language locale
        // localeId: 'id-ID', // Bahasa Indonesia locale
      );
      if (available) {
        setState(() {
          _isListening = true;
          fromAudioCommand = true;

          commandResult();

          _text = "Listening...";
          print("Listening...");
        });

        // // stop listening
        _microphoneTimeout2();
      } else {
        print('The user denied the use of speech recognition.');
      }
    }
  }

  static Future<String> translateText(
      String text, String from, String to) async {
    final translator = GoogleTranslator();

    Translation translation =
        await translator.translate(text, from: from, to: to);

    return translation.text;
  }

  commandResult() {
    _speech.listen(
        localeId: MapPage.isIndonesianSelected ? "id" : "en",
        onResult: (result) {
          setState(() {
            fromAudioCommand = true;

            _text = result.recognizedWords.toLowerCase();
            print(_text);
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 1000), () async {
              if (_text.contains("go") ||
                  _text.contains("going") ||
                  _text.contains("pergi")) {
                print("go");

                print("go");
                fromAudioCommand = true;

                // Split recognized words by space
                List<String> words = _text.split(" ");
                // Find the index of the keyword
                int keywordIndex = words.indexOf("go");
                if (keywordIndex == -1) {
                  keywordIndex = words.indexOf("going");
                }
                if (keywordIndex == -1) {
                  keywordIndex = words.indexOf("pergi");
                }
                // Extract the destination word after the keyword
                String destination = words.sublist(keywordIndex + 1).join(" ");
                _endSearchFieldController.text = destination;
                if (_endSearchFieldController.text.isNotEmpty) {
                  autoCompleteSearch(_endSearchFieldController.text);
                  print(fromAudioCommand);
                }
              } else if (_text.contains("stop") ||
                  _text.contains("exit") ||
                  _text.contains("berhenti")) {
                if (MapPage.isStartNavigate) {
                  TextToSpeech.speak("Exiting navigation");
                  MapPage.isStartNavigate = false;
                  return;
                }
                TextToSpeech.speak(
                    "To exit navigate. you have to start navigate first");
              } else if (_text.contains("start") ||
                  _text.contains("navigate") ||
                  _text.contains("navigation") ||
                  _text.contains("mulai") ||
                  _text.contains("navigasi")) {
                if (MapPage.destinationCoordinate.latitude != 0) {
                  if (!MapPage.isStartNavigate) {
                    MapPage.isStartNavigate = true;
                    NavigateMethod().startNavigate(
                      MapPage.mapController,
                      MapPage.destinationCoordinate,
                    );
                    TextToSpeech.speak(
                        "Start navigation to ${MapPage.googleMapDetail['name']}");
                    return;
                  } else {
                    TextToSpeech.speak(
                        "You are already navigating. Your destination is set to ${MapPage.googleMapDetail['name']}");
                  }
                } else {
                  TextToSpeech.speak(
                      "to start navigate. you have to set your destination first. To set the destination, you need to search your destination using the search bar and select where you want to go. or, you can double tap the screen to activate the audio command. Say 'navigate destination' or 'going destination' to set your destination");
                }
              } else if (_text.contains("in front") ||
                  _text.contains("ada apa") ||
                  _text.contains("apa yang") ||
                  _text.contains("yang ada") ||
                  _text.contains("rintangan") ||
                  _text.contains("depan")) {
                ObjectDetector().checkInFront();
                // Iterate through the detection result to count objects in front
                // int objectsInFront = 0;
                // for (var detection in detectionResult) {
                //   // Check if the object's position indicates it's in front
                //   // You may need to adjust these conditions based on your scenario
                //   if (detection['box'][1] > SOME_THRESHOLD && detection['box'][2] > SOME_OTHER_THRESHOLD) {
                //     objectsInFront++;
                //   }
                // }
              } else if (_text.contains("next") ||
                  _text.contains("step") ||
                  _text.contains("selanjutnya") ||
                  _text.contains("langkah ")) {
                if (MapPage.isStartNavigate) {
                  TextToSpeech.speak(
                      "your next step is.${MapPage.distance}meters, $instruction");
                } else {
                  TextToSpeech.speak(
                      "you need to start navigation first. To start navigation, say 'start navigate'.");
                }
              } else if (_text.contains("destination") ||
                  _text.contains("location") ||
                  _text.contains("destinasi") ||
                  _text.contains("saat ini") ||
                  _text.contains("tujuan") ||
                  _text.contains("lokasi")) {
                if (MapPage.destinationLocationName != "") {
                  TextToSpeech.speak(
                      "your current destination is set to ${MapPage.destinationLocationName}");
                } else {
                  TextToSpeech.speak(
                      "You do destination is null. To set the destination, you need to search your destination using the search bar and select where you want to go. or, you can double tap the screen to activate the audio command. Say 'navigate destination' or 'going destination' to set your destination");
                }
              } else if (_text.contains("share") || _text.contains("bagikan")) {
                if (MapPage.destinationCoordinate.latitude != 0) {
                  if (MapPage.isStartNavigate) {
                    if (AuthService.isAuthenticate) {
                      final String? userName = AuthService.userName;
                      TextToSpeech.speak(
                          "Start sharing your location. You need to give your username to other people $userName so they can track your location");

                      ShareLocation.shareUserLocation(
                        LatLng(MapPage.userLatitude, MapPage.userLongitude),
                        MapPage.destinationCoordinate,
                        MapPage.total_distance,
                        MapPage.total_duration,
                        MapPage.destinationLocationName,
                        MapPage.nearLocationAddress,
                      );
                    } else {
                      TextToSpeech.speak(
                          "In order to share your location, you need to login first. Navigating to the login page");
                      Get.to(const LoginPage());
                    }
                  } else {
                    TextToSpeech.speak(
                        "In order to share location, you need to start navigation. To start navigation, say 'start navigate'.");
                  }
                } else {
                  TextToSpeech.speak(
                      "In order to share your location, you need to set your destination. To set the destination, you need to search your destination using the search bar and select where you want to go. or, you can double tap the screen to activate the audio command. Say 'navigate destination' or 'going destination' to set your destination");
                }
              } else if (_text.contains("language") ||
                  _text.contains("indonesia") ||
                  _text.contains("bahasa") ||
                  _text.contains("english") ||
                  _text.contains("switch") ||
                  _text.contains("ganti")) {
                MapPage.isIndonesianSelected = !MapPage.isIndonesianSelected;
                _saveSetting();

                if (MapPage.isIndonesianSelected) {
                  TextToSpeech.speak(
                      "mengubah bahasa default Anda, ke bahasa indonesia");
                } else {
                  TextToSpeech.speak("change your default language to english");
                }
              } else {
                if (_text != "Listening...") {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 1000), () {
                    // stop listening
                    _microphoneTimeout1();
                  });
                }
              }
            });
          });
        });
  }

  // stop listening after 8 seconds
  void _microphoneTimeout1() {
    Timer(const Duration(seconds: 1), () {
      fromAudioCommand = true;

      print(fromAudioCommand);
      // Reset _isListening 8 seconds
      setState(() {
        _isListening = false;
        _text = ""; // Clear the recognized text
      });
      _speech.stop();
      MapPage.canNotify = true;
      print("Speech recognition timeout");
    });
  }

  // stop listening if the user did not say anything
  void _microphoneTimeout2() {
    Timer(const Duration(seconds: 8), () {
      // Reset _isListening if no speech is recognized after 5 seconds
      setState(() {
        _isListening = false;
        _text = ""; // Clear the recognized text
      });
      _speech.stop();
      print("Speech recognition timeout");
      MapPage.canNotify = true;
    });
  }

  void callbackSetState() {
    setState(() {});
  }
}
