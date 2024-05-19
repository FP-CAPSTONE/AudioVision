import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/pages/map_page/method/share_location_method.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:flutter/material.dart';

class CustomBottomSheet extends StatefulWidget {
  final Function shareLocationCallback;
  const CustomBottomSheet({
    super.key,
    required this.shareLocationCallback,
  });

  @override
  _CustomBottomSheetState createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  late Map<String, dynamic> totals;

  @override
  void initState() {
    super.initState();
    totals = _calculateTotals(MapPage.allSteps);
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    int totalDurationMinutes = totals['totalDuration'];
    DateTime expectedArrivalTime =
        now.add(Duration(minutes: totalDurationMinutes));

    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 3,
                  color: const Color.fromARGB(255, 221, 221, 221),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 20, left: 20, right: 20, top: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                MapPage.isIndonesianSelected
                                    ? '${totals['totalDuration']} menit '
                                    : '${totals['totalDuration']} mins ',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${totals['totalDistance'].toStringAsFixed(2)} km • ${expectedArrivalTime.hour.toString().padLeft(2, '0')}.${expectedArrivalTime.minute.toString().padLeft(2, '0')} ',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ShareLocation.isShared
                                  ? Container()
                                  : GestureDetector(
                                      onLongPress: () {
                                        TextToSpeech.speak("Share Button");
                                      },
                                      child: SizedBox(
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.15,
                                        child: ElevatedButton(
                                            onPressed: () {
                                              widget.shareLocationCallback(
                                                  context);
                                            },
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(
                                                const Color.fromARGB(
                                                    255, 36, 36, 36),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.share,
                                              color: Colors.white,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.08,
                                            )),
                                      ),
                                    ),
                              const SizedBox(
                                width: 5,
                              ),
                              GestureDetector(
                                onLongPress: () {
                                  TextToSpeech.speak("Exit Button");
                                },
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.15,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ShareLocation.isShared = false;
                                      NavigateMethod.stopNavigate();
                                      // PolylineMethod(getDirectionImage)
                                      //     .clearPolyline(); // getDirectionImage will not use in here
                                    },
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.red),
                                    ),
                                    child: Text(
                                      MapPage.isIndonesianSelected
                                          ? "Keluar"
                                          : "Exit",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey.withOpacity(0.5),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: MapPage.allSteps.length,
                  itemBuilder: (context, index) {
                    var step = MapPage.allSteps[index];
                    var maneuver = step['maneuver'] ?? "continue";
                    return GestureDetector(
                      onLongPress: () {
                        TextToSpeech.speak(step['instructions']);
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        title: Text(
                          step['instructions'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.043),
                        ),
                        subtitle: Text(
                          '${step['distance']} - ${step['duration']}',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.038),
                        ),
                        leading: getDirectionImage(maneuver),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to calculate total distance and total duration
  Map<String, dynamic> _calculateTotals(List<dynamic> steps) {
    double totalDistance = 0.0;
    int totalDuration = 0;
    print("object");

    for (var step in steps) {
      print("object $step");
      // Extract the distance value and unit from step['distance']
      List<String> distanceParts = step['distance'].split(' ');
      String distanceString = distanceParts[0].toString();
      double distanceValue = double.parse(distanceString.replaceAll(',', '.'));
      String distanceUnit = distanceParts[1];

      // Convert distance to kilometers if it's in meters
      if (distanceUnit == 'm') {
        distanceValue /= 1000; // Convert meters to kilometers
      }

      // Add the converted distance to the total distance
      totalDistance += distanceValue;

      // Add the duration to the total duration
      totalDuration += int.parse(step['duration'].split(' ')[0]);
    }

    // Update total duration outside the loop
    MapPage.totalDurationToDestination = totalDuration;

    return {'totalDistance': totalDistance, 'totalDuration': totalDuration};
  }

  Widget getDirectionImage(String maneuver) {
    String imagePath;
    switch (maneuver.toLowerCase()) {
      // case 'turn-slight-left':
      //   imagePath = 'assets/images/directions/turn-slight-left.png';
      //   break;
      // case 'turn-sharp-left':
      //   imagePath = 'assets/images/directions/turn-sharp-left.png';
      //   break;
      // case 'uturn-left':
      //   imagePath = 'assets/images/directions/uturn-left.png';
      //   break;
      case 'turn-left':
        imagePath = 'assets/images/directions/turn-left.png';
        break;
      case 'turn-slight-right':
        imagePath = 'assets/images/directions/turn-slight-right.png';
        break;
      // case 'turn-sharp-right':
      //   imagePath = 'assets/images/directions/turn-sharp-right.png';
      //   break;
      // case 'uturn-right':
      //   imagePath = 'assets/images/directions/uturn-right.png';
      //   break;
      case 'turn-right':
        imagePath = 'assets/images/directions/turn-right.png';
        break;
      case 'straight':
        imagePath = 'assets/images/directions/straight.png';
        break;
      // case 'ramp-left':
      //   imagePath = 'assets/images/directions/ramp-left.png';
      //   break;
      // case 'ramp-right':
      //   imagePath = 'assets/images/directions/ramp-right.png';
      //   break;
      // case 'merge':
      //   imagePath = 'assets/images/directions/merge.png';
      //   break;
      // case 'fork-left':
      //   imagePath = 'assets/images/directions/fork-left.png';
      //   break;
      // case 'fork-right':
      //   imagePath = 'assets/images/directions/fork-right.png';
      //   break;
      // case 'ferry':
      //   imagePath = 'assets/images/directions/ferry.png';
      //   break;
      // case 'ferry-train':
      //   imagePath = 'assets/images/directions/ferry-train.png';
      //   break;
      // case 'roundabout-left':
      //   imagePath = 'assets/images/directions/roundabout-left.png';
      //   break;
      // case 'roundabout-right':
      //   imagePath = 'assets/images/directions/roundabout-right.png';
      //   break;
      default:
        // Use a default image if the maneuver type is not recognized
        imagePath = 'assets/images/directions/straight.png';
        break;
    }

    return Container(
      padding: const EdgeInsets.only(right: 20),
      child: Tab(
        icon: Image.asset(
          imagePath,
          height: MediaQuery.of(context).size.width * 0.12,
          color: Colors.black,
        ),
      ),
    );
  }
}
