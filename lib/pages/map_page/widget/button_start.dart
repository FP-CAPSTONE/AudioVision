import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ButtonStartNavigateWidget extends StatelessWidget {
  final GoogleMapController mapController;

  const ButtonStartNavigateWidget({
    super.key,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return !MapPage.isStartNavigate
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
                      NavigateMethod().startNavigate(
                        mapController,
                        MapPage.destinationCoordinate,
                      );
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
}
