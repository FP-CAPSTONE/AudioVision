// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:audiovision/pages/map_page/method/marker_method.dart';
import 'package:audiovision/pages/map_page/widget/buttom_sheet_detail_ocation.dart';
import 'package:audiovision/pages/map_page/method/searching_method.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:audiovision/pages/auth_page/login.dart';
import 'package:audiovision/pages/auth_page/services/auth_services.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/pages/map_page/method/polyline_mothod.dart';
import 'package:audiovision/pages/map_page/method/share_location_method.dart';
import 'package:audiovision/pages/map_page/widget/bottom_sheet.dart';
import 'package:audiovision/pages/map_page/widget/button_start.dart';
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
// ned to change the class name, there are two location service
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vibration/vibration.dart';
import '../setting_page/setting.dart';

class MapPage extends StatefulWidget {
  //public variable
  static double userLatitude = 0;
  static double userLongitude = 0;
  static LatLng userPreviousCoordinate = const LatLng(0, 0);

  static LatLng destinationCoordinate = const LatLng(0, 0);

  static bool isStartNavigate = false;

  static GoogleMapController? mapController;

  static List<dynamic> allSteps = [];
  static Map<String, dynamic> endLocation = {};

  static Map googleMapDetail = {
    "name": "",
    "rating": 0,
    "ratingTotal": 0,
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
  static String destinationLocationName = "";

  static double compassHeading = 0;

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

    String apiKey = dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
    googlePlace = GooglePlace(apiKey);

    endFocusNode = FocusNode();

    listenToUserLocation(locationService);
    ShareLocation.dbRef = FirebaseDatabase.instance.ref();

    isLogin();
    print("init");
    _initCompass();

    DefaultAssetBundle.of(context)
        .loadString("assets/maptheme/custom_map.json")
        // .loadString("assets/maptheme/night_map.json")
        .then((value) {
      mapTheme = value;
    });
    //_checkDeviceOrientation();
  }

  // Initialize compass and start listening to updates
  void _initCompass() {
    print("init");
    FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        double compassHeading = event.heading ?? 0;

        // Check if the difference between the current compass heading and the previous heading is greater than 5 degrees
        if ((compassHeading - MapPage.compassHeading).abs() > 10) {
          MapPage.compassHeading = compassHeading;

          // Update marker and camera rotation only when the rotation of the compass > 5 degrees
          MarkerMethod.updateMarkerAndCameraRotation();
        }
      });
    });
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
        var result = await googlePlace.autocomplete
            .get(value,
                origin: LatLon(MapPage.userLatitude, MapPage.userLongitude))
            .timeout(
                Duration(seconds: 15)); // Adjust timeout duration as needed

        if (result != null && result.predictions != null && mounted) {
          setState(() {
            predictions = result.predictions!;

            if (predictions.isNotEmpty && fromAudioCommand == true) {
              SearchMethod.save_search_log(
                  predictions[0].description.toString(),
                  predictions[0].placeId.toString());

              TextToSpeech.speak("set destination to " +
                  predictions[0].description.toString() +
                  ". double tap the screen. and. say Start navigate. to start navigation");
              add_destination(predictions[0].placeId.toString());
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
      body: GestureDetector(
        onDoubleTap: () {
          TextToSpeech.speak("Audio command activated, say something");
          _isListening = false;
          _text = '';
          Vibration.vibrate();
          _listen();
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
                              const Icon(
                                Icons.mic,
                                size: 50,
                                color: Colors.red,
                              ),
                              SizedBox(
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
                        : SizedBox(),
                  ),

                  MapPage.isStartNavigate
                      ? CustomBottomSheet(
                          callback: shareLocation,
                        )
                      : Container(),
                  !MapPage.isStartNavigate &&
                          MapPage.destinationCoordinate.latitude != 0
                      ? BottomSheetDetailLocation()
                      : Container(),
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
                              : MapPage.destinationCoordinate.latitude == 0
                                  ? Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Color.fromARGB(255, 0, 0, 0),
                                      ),
                                      width: MediaQuery.of(context).size.width *
                                          0.9,
                                      height: 55,
                                      child: Material(
                                        // Wrap ElevatedButton with Material
                                        borderRadius: BorderRadius.circular(
                                            8), // Apply the same border radius
                                        color: Color.fromARGB(255, 0, 0,
                                            0), // Apply the same color
                                        child: InkWell(
                                          // Wrap ElevatedButton with InkWell for ripple effect
                                          borderRadius: BorderRadius.circular(
                                              8), // Apply the same border radius
                                          onTap: () {
                                            TextEditingController
                                                _userNameController =
                                                TextEditingController();
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title:
                                                      Text('Tracking Location'),
                                                  content: TextField(
                                                    controller:
                                                        _userNameController,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'Enter Username',
                                                    ),
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        String userName =
                                                            _userNameController
                                                                .text
                                                                .trim();
                                                        if (userName.isEmpty) {
                                                          // Handle empty email
                                                          TextToSpeech.speak(
                                                              "Please enter the user name.");
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: const Text(
                                                                  'Please enter the Username.'),
                                                            ),
                                                          );
                                                          return;
                                                        }
                                                        // Perform actions with the entered user ID
                                                        print(
                                                            'User ID entered: $userName');
                                                        ShareLocation
                                                                .trackingUserName =
                                                            userName;
                                                        ShareLocation
                                                            .getOtherUserLocation();
                                                        // Close the dialog
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text('OK'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    10), // Adjust padding to match the original design
                                            child: Center(
                                              child: Text(
                                                'Tracking Location',
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.045,
                                                  color: Colors
                                                      .white, // Set text color to white
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
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
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
                          hintText: "Search Here",
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
                              "Clicking search bar. search where you want to go. and hold the screen to read the search result. otherwise. you can double tap the screen to activate the audio command. say.   'navigate destination' or 'going destination' to set your destination");
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
                    Get.to(() => SettingPage());
                    // Add your settings icon onPressed logic here
                  },
                  icon: const Icon(Icons.settings),
                  color: Color.fromARGB(255, 212, 212, 212),
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
                    print("res" + predictions[index].description.toString());
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
                            TextToSpeech.speak("set destination to " +
                                predictions[index].description.toString() +
                                ". double tap the screen. and. say Start navigate. to start navigation");
                            await SearchMethod.save_search_log(
                              predictions[index].terms!.first.value.toString(),
                              predictions[index].placeId.toString(),
                            );
                            add_destination(
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
                    print("res" + log);
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
                            add_destination(placeId);
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
        distanceMeters.toString() + " m",
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      );
    } else if (distanceMeters < 10000) {
      // Convert distance from meters to kilometers and format it as "0.0 km"
      String formattedDistance =
          (distanceMeters / 1000.0).toStringAsFixed(1) + " km";
      return Text(
        formattedDistance,
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      );
    } else {
      // If it's too far, just show the icon
      return SizedBox.shrink(); // This returns an empty widget
    }
  }

// add destination when user clck the listview <- SHOULD MOVE TO ANOTHER FILE
  void add_destination(String placeId) async {
    MapPage.googleMapDetail['photoReference'] =
        []; // remove all photo in here if any
    final Uint8List markerIcon = await MarkerMethod.getBytesFromAsset(
        'assets/markers/destination_fill.png', 100);

    final details = await googlePlace.details.get(placeId);
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
        String url =
            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=' +
                dotenv.env['GOOGLE_MAPS_API_KEYS'].toString();
        MapPage.googleMapDetail['photoReference']
            .add(photoReference); // Add URLs to the 'images' list
      }
    }
    print("kontrol" + details.result!.name.toString());
    print("kontrol" + details.result!.photos.toString());
    print("kontrol" + details.result!.rating.toString());
    print("kontrol" + details.result!.userRatingsTotal.toString());
    if (details != null && details.result != null && mounted) {
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
        infoWindow: InfoWindow(title: "You"),
        rotation: MapPage.compassHeading,

        anchor: const Offset(0.5, 0.5),
      ),
    );

    MapPage.userPreviousCoordinate =
        LatLng(MapPage.userLatitude, MapPage.userLongitude);

    setState(() {});
    if (MapPage.isStartNavigate) {
      PolylineMethod(updateUi!).getPolyline(
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

  String maneuver = "";
  String distance = "";
  String instruction = "";
  void routeGuidance() async {
    if (MapPage.isStartNavigate) {
      if (stepIndex < MapPage.allSteps.length) {
        print(stepIndex);
        double distanceToStep = await calculateDistance(
          MapPage.userLatitude,
          MapPage.userLongitude,
          MapPage.allSteps[stepIndex]['end_lat'],
          MapPage.allSteps[stepIndex]['end_long'],
        );
        print(MapPage.allSteps);

        int roundedDistance = distanceToStep.ceil();

        // Assuming there's a threshold distance to trigger the notification
        double thresholdDistance = 100; // meters
        print("WOYYYYYYYYYYYYYYYYYYYYYYYY");
        print(MapPage.allSteps);
        print(distanceToStep);
        if (distanceToStep <= thresholdDistance) {
          maneuver = MapPage.allSteps[stepIndex]['maneuver'] ?? 'Continue';
          instruction =
              MapPage.allSteps[stepIndex]['instructions'] ?? 'Continue';
          distance = MapPage.allSteps[stepIndex]['distance'] ?? '0 m';
          print("MASIHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH");
          print("In $roundedDistance metersss $maneuver");
          TextToSpeech.speak("In $roundedDistance meters $maneuver");
          stepIndex++;
        }

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

  void shareLocation(BuildContext context) {
    if (!AuthService.isAuthenticate) {
      Get.to(LoginPage());
      TextToSpeech.speak(
          "You are not logged in. To share your location, you must log in first.");
      return;
    }
    String userName = AuthService.userName.toString();
    TextToSpeech.speak(
        'Do you want to share your location?. To share your location, Share your Email to other people. your username is $userName.split("")');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share Location?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to share your location? To share your location, Share your username to other people. your username is $userName',
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text('No'),
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
                    child: Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((value) {
      if (value == true) {
        ShareLocation.shareUserLocation(
          LatLng(MapPage.userLatitude, MapPage.userLongitude),
          MapPage.destinationCoordinate,
          MapPage.destinationLocationName,
        );
      }
    });
  }

  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _text = '';

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          fromAudioCommand = true;

          _text = "Listening...";
          print("Listening...");
        });

        _speech.listen(onResult: (result) {
          setState(() {
            fromAudioCommand = true;

            _text = result.recognizedWords.toLowerCase();
            print(_text);

            if (_text.contains("go") ||
                _text.contains("going") ||
                _text.contains("navigate")) {
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
                keywordIndex = words.indexOf("navigate");
              }
              // Extract the destination word after the keyword
              String destination = words.sublist(keywordIndex + 1).join(" ");
              _endSearchFieldController.text = destination;
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 1000), () {
                if (_endSearchFieldController.text.isNotEmpty) {
                  autoCompleteSearch(_endSearchFieldController.text);
                  print(fromAudioCommand);
                }
              });
            } else if (_text.contains("stop") || _text.contains("exit")) {
              if (MapPage.isStartNavigate) {
                TextToSpeech.speak("Exiting navigation");
                MapPage.isStartNavigate = false;
                return;
              }
              TextToSpeech.speak(
                  "To exit navigate. you have to start navigate first");
            } else if (_text.contains("start")) {
              if (!MapPage.isStartNavigate &&
                  MapPage.destinationCoordinate.latitude != 0) {
                MapPage.isStartNavigate = true;
                NavigateMethod().startNavigate(
                  MapPage.mapController,
                  MapPage.destinationCoordinate,
                );
                TextToSpeech.speak("Start navigation to " +
                    MapPage.googleMapDetail['name'].toString());

                return;
              } else {
                TextToSpeech.speak(
                    "You are already navigating. Your destination is set to " +
                        MapPage.googleMapDetail['name'].toString());
              }
            } else if (_text.contains("in front")) {
              // Iterate through the detection result to count objects in front
              // int objectsInFront = 0;
              // for (var detection in detectionResult) {
              //   // Check if the object's position indicates it's in front
              //   // You may need to adjust these conditions based on your scenario
              //   if (detection['box'][1] > SOME_THRESHOLD && detection['box'][2] > SOME_OTHER_THRESHOLD) {
              //     objectsInFront++;
              //   }
              // }
              TextToSpeech.speak("there are 2 people in front of you");
            } else if (_text.contains("share")) {
              if (MapPage.destinationCoordinate.latitude != 0) {
                if (MapPage.isStartNavigate) {
                  if (AuthService.isAuthenticate) {
                    final String? userName = AuthService.userName;
                    TextToSpeech.speak(
                        "Start sharing your location. You need to give your username to other people $userName so they can track your location");

                    ShareLocation.shareUserLocation(
                      LatLng(MapPage.userLatitude, MapPage.userLongitude),
                      MapPage.destinationCoordinate,
                      MapPage.destinationLocationName,
                    );
                  } else {
                    TextToSpeech.speak(
                        "In order to share your location, you need to login first. Navigating to the login page");
                    Get.to(LoginPage());
                  }
                } else {
                  TextToSpeech.speak(
                      "In order to share location, you need to start navigation. To start navigation, say 'start navigate'.");
                }
              } else {
                TextToSpeech.speak(
                    "In order to share your location, you need to set your destination. To set the destination, you need to search your destination using the search bar and select where you want to go. Otherwise, you can double tap the screen to activate the audio command. Say 'navigate destination' or 'going destination' to set your destination");
              }
            } else {
              // stop listening
              _microphoneTimeout1();
            }
          });
        });
        // stop listening
        _microphoneTimeout2();
      } else {
        print('The user denied the use of speech recognition.');
      }
    }
  }

  // stop listening after 8 seconds
  void _microphoneTimeout1() {
    Timer(const Duration(seconds: 9), () {
      // Reset _isListening 8 seconds
      setState(() {
        _isListening = false;
        _text = ""; // Clear the recognized text
      });
      print("Speech recognition timeout");
    });
  }

  // stop listening if the user did not say anything
  void _microphoneTimeout2() {
    Timer(const Duration(seconds: 6), () {
      if (_text == "Listening...") {
        // Reset _isListening if no speech is recognized after 5 seconds
        setState(() {
          _isListening = false;
          _text = ""; // Clear the recognized text
        });
        print("Speech recognition timeout");
      }
    });
  }
}
