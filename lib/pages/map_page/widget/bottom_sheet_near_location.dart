import 'dart:typed_data';

import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/marker_method.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

class BottomSheetNearLocation extends StatefulWidget {
  final Function addDestinationCallback;
  static String destinationPlaceId = "";
  const BottomSheetNearLocation(this.addDestinationCallback, {super.key});
  @override
  _BottomSheetNearLocationState createState() =>
      _BottomSheetNearLocationState();
}

class _BottomSheetNearLocationState extends State<BottomSheetNearLocation> {
  @override
  void initState() {
    super.initState();
  }

  LatLng destinationCoordinate = const LatLng(0, 0);
  String destinationPlaceName = "";

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      // controller: DraggableScrollableController(),
      expand: true,
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.35,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 10, bottom: 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onLongPress: () {
                                  TextToSpeech.speak(
                                      "the nearest location chosen is  $destinationPlaceName");
                                },
                                child: Text(
                                  MapPage.isIndonesianSelected
                                      ? "Lokasi terdekat"
                                      : "Nearby location",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                MapPage.isIndonesianSelected
                                    ? "Pilih lokasi terdekat untuk dikunjungi"
                                    : "Select a nearby location to go",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.032,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onLongPress: () {
                            TextToSpeech.speak("Start Button");
                          },
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.07,
                            child: ElevatedButton(
                              onPressed: () {
                                MapPage.destinationCoordinate =
                                    destinationCoordinate;
                                MapPage.destinationLocationName =
                                    destinationPlaceName;
                                widget.addDestinationCallback(
                                    BottomSheetNearLocation
                                        .destinationPlaceId); //     addNearbyMarker did not use here

                                // this will fill the steps in mappage
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
                                Future.delayed(const Duration(seconds: 3), () {
                                  NavigateMethod().startNavigate(
                                    MapPage.mapController,
                                    MapPage.destinationCoordinate,
                                  );
                                });
                                setState(() {});

                                TextToSpeech.speak(
                                    "Start navigation to $destinationPlaceName");
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.black),
                              ),
                              child: Text(
                                MapPage.isIndonesianSelected
                                    ? "Mulai"
                                    : "Start",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Column(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     Text(
              //       MapPage.googleMapDetail['type'].toString(),
              //       style: const TextStyle(
              //           fontWeight: FontWeight.bold,
              //           color: Colors.grey,
              //           fontSize: 10),
              //     ),
              //     Text(
              //       MapPage.googleMapDetail['rating'].toString(),
              //       style: const TextStyle(
              //           fontWeight: FontWeight.bold,
              //           color: Colors.grey,
              //           fontSize: 10),
              //     ),
              //   ],
              // ),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.grey.withOpacity(0.5),
              ),

              GestureDetector(
                onLongPress: () {
                  TextToSpeech.speak(
                      "this is a nearby location selection. the nearest location chosen is $destinationPlaceName. Scroll down or scroll up to select the closest location ");
                },
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.18,
                  width: double.infinity,
                  child: CupertinoPicker(
                    // squeeze: ,
                    // key: ,
                    // diameterRatio: 1,
                    // backgroundColor: Colors.grey[300],
                    selectionOverlay: Container(
                      height: MediaQuery.of(context).size.height * 0.1,
                      decoration: BoxDecoration(
                        color: Colors.grey[800]
                            ?.withOpacity(0.1), // Set color to transparent
                      ),
                    ),

                    itemExtent: MediaQuery.of(context).size.height * 0.1,
                    offAxisFraction: 0.5, // 0
                    magnification: 1, // 1
                    diameterRatio: 30,
                    squeeze: 1.4,

                    useMagnifier: false,
                    scrollController:
                        FixedExtentScrollController(initialItem: 1),
                    onSelectedItemChanged: (int value) {
                      addNearbyMarker(value);
                    },
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        width: 2000,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildText(
                              MapPage.nearbyLocationResponse?.results?[1].name,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            _buildText(
                              MapPage
                                  .nearbyLocationResponse?.results?[1].vicinity,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.033,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(15),
                        width: 2000,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildText(
                              MapPage.nearbyLocationResponse?.results?[2].name,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            _buildText(
                              MapPage
                                  .nearbyLocationResponse?.results?[2].vicinity,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.033,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(15),
                        width: 2000,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildText(
                              MapPage.nearbyLocationResponse?.results?[3].name,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            _buildText(
                              MapPage
                                  .nearbyLocationResponse?.results?[3].vicinity,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.033,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(15),
                        width: 2000,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildText(
                              MapPage.nearbyLocationResponse?.results?[4].name,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            _buildText(
                              MapPage
                                  .nearbyLocationResponse?.results?[4].vicinity,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.033,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildText(String? text,
      {double? fontSize, FontWeight? fontWeight, Color? color}) {
    if (text != null && text.isNotEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else {
      // Placeholder for loading skeleton or "Loading..." text
      return Text(
        "Loading nearby location...",
        style: TextStyle(
          color: color ?? Colors.black, // Use default color if not provided
          fontSize: fontSize ?? 14, // Use default font size if not provided
          fontWeight: fontWeight ??
              FontWeight.normal, // Use default font weight if not provided
          overflow: TextOverflow.ellipsis,
        ),
      );
      // return _buildLoadingPlaceholder(
      //     width: color == Colors.grey
      //         ? double.infinity
      //         : MediaQuery.of(context).size.width * 0.2,
      //     height: MediaQuery.of(context).size.height * 0.050);
    }
  }

  Widget _buildLoadingPlaceholder(
      {double? width, double? height, Color? color}) {
    return Shimmer.fromColors(
      baseColor: color ?? Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: color ?? Colors.grey[300]!,
      ),
    );
  }

  addNearbyMarker(int value) async {
    Map detailNearby = MapPage.nearbyLocationDetails[value];

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

    destinationCoordinate = LatLng(detailNearby['lat'], detailNearby['long']);
    destinationPlaceName = detailNearby['placeName'];
    BottomSheetNearLocation.destinationPlaceId = detailNearby['placeId'];
    print(destinationPlaceName);
    TextToSpeech.speak(" the nearest location is set to $destinationPlaceName");
  }
}
