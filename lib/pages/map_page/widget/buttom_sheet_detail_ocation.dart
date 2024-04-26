import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/navigate_method.dart';
import 'package:audiovision/utils/text_to_speech.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BottomSheetDetailLocation extends StatefulWidget {
  @override
  _BottomSheetDetailLocationState createState() =>
      _BottomSheetDetailLocationState();
}

class _BottomSheetDetailLocationState extends State<BottomSheetDetailLocation> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
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
                  padding:
                      EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onLongPress: () {
                                    TextToSpeech.speak(
                                        "your destination is ${MapPage.googleMapDetail['name']}");
                                  },
                                  child: Text(
                                    MapPage.googleMapDetail['name'],
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.042,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                SizedBox(height: 5),
                                MapPage.googleMapDetail['rating'] != null
                                    ? Container(
                                        child: Row(
                                          children: [
                                            Text(
                                              MapPage.googleMapDetail['rating']
                                                  .toString(),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.028),
                                            ),
                                            const SizedBox(width: 5),
                                            RatingBar.builder(
                                              itemSize: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.045,
                                              initialRating: MapPage
                                                  .googleMapDetail['rating'],
                                              direction: Axis.horizontal,
                                              allowHalfRating: true,
                                              itemCount: 5,
                                              itemBuilder: (context, _) =>
                                                  const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                              onRatingUpdate: (rating) {
                                                print(rating);
                                              },
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              "(${MapPage.googleMapDetail['ratingTotal']})",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.028),
                                            )
                                          ],
                                        ),
                                      )
                                    : Text(
                                        "No reviews",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.03),
                                      ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onLongPress: () {
                              TextToSpeech.speak("Start Button");
                            },
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.07,
                              child: ElevatedButton(
                                onPressed: () {
                                  NavigateMethod().startNavigate(
                                    MapPage.mapController,
                                    MapPage.destinationCoordinate,
                                  );
                                  TextToSpeech.speak("Start navigation");
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.black),
                                ),
                                child: Text(
                                  "Start",
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
                SizedBox(
                  height: 5,
                ),

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              10.0), // Adjust the value for the desired roundness
                        ),
                        child: MapPage.googleMapDetail['photoReference'].isEmpty
                            ? Container(
                                // Display a placeholder widget if the list is empty
                                height:
                                    200, // Adjust the height according to your design
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Text(
                                  "No images available",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : CarouselSlider.builder(
                                itemCount: MapPage
                                    .googleMapDetail['photoReference'].length,
                                itemBuilder: (context, index, realndex) {
                                  final photoRef = MapPage
                                      .googleMapDetail['photoReference'][index];

                                  return buildImage(photoRef, index);
                                },
                                options: CarouselOptions(
                                  height: 400,
                                  enableInfiniteScroll: false,
                                ),
                              ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildImage(String photoRef, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
            10), // Adjust the value for the desired roundness of the container
      ),
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            10), // Adjust the value for the desired roundness of the image
        child: Image.network(
          "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=" +
              dotenv.env['GOOGLE_MAPS_API_KEYS'].toString(),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
