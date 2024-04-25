import 'package:audiovision/utils/text_to_speech.dart';
import 'package:flutter/material.dart';

class NavigateBarWidget extends StatelessWidget {
  final String navigationText;
  final String distance;
  final String manuever;
  final String instruction;
  const NavigateBarWidget({
    super.key,
    required this.navigationText,
    required this.distance,
    required this.manuever,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        TextToSpeech.speak("in" + distance + ", " + instruction);
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.2,
        padding: EdgeInsets.only(
            top: 20.0,
            left: 20.0,
            right: 20.0,
            bottom: 10), // Adjust the padding as needed
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(7)),
          color: Color.fromARGB(255, 24, 24, 24),
          // color: Color.fromARGB(255, 255, 255, 255),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ImageIcon(
            //   AssetImage('assets/images/directions/dturn-left.png'),
            // ),
            // Tab(
            //   text: 'Image',
            //   icon: Image.asset(
            //     'assets/images/directions/turn-left.png',
            //     height: 44,
            //     fit: BoxFit.cover,
            //   ),
            // ),
            getDirectionImage(manuever),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      distance,
                      style: TextStyle(color: Colors.white70),
                      overflow: TextOverflow
                          .ellipsis, // Optional: specify overflow behavior
                    ),
                  ),
                  Flexible(
                    child: Text(
                      instruction,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                      overflow: TextOverflow
                          .ellipsis, // Optional: specify overflow behavior
                    ),
                  ),
                ],
              ),
            )

            // buildArrowDirectionContainer(manuever, distance, "turn-left"),
            // Expanded(
            //   child:
            //       NowNavigationTextWidget(text: navigationText, fontSize: 18.0),
            // ),
            // Container(
            //   decoration: const BoxDecoration(
            //     shape: BoxShape.circle,
            //     color: Color.fromARGB(255, 255, 255, 255),
            //   ),
            //   padding: EdgeInsets.all(8.0),
            //   child: Icon(
            //     Icons.mic,
            //     color: Colors.blue[400],
            //   ),
            // ),
          ],
        ),
      ),
    );
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
      padding: EdgeInsets.only(right: 20),
      child: Tab(
        icon: Image.asset(
          imagePath,
          height: 35,
          color: Colors.white,
        ),
      ),
    );
  }
}
            // ImageIcon(
              //   AssetImage('assets/images/directions/turn-left.png'),
              //   size: 24, // Adjust size as needed
              //   color: Colors.black, // Adjust color as needed
              // ),
              // Text(
              //   distance,
              //   style: TextStyle(
              //     fontSize: 15.0,
              //     color: Colors.white,
              //   ),
              // ),