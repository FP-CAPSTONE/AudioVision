import 'package:audiovision/pages/map_page/map.dart';
import 'package:audiovision/pages/map_page/method/share_location_method.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

class PanelWidget extends StatelessWidget {
  final ScrollController controller;
  final PanelController panelController;

  const PanelWidget({
    Key? key,
    required this.controller,
    required this.panelController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.zero,
        controller: controller,
        children: <Widget>[
          SizedBox(
            height: 12,
          ),
          buildDragHandle(),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.account_circle, size: 30),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex:
                    2, // Memberikan flex lebih besar agar kolom ini lebih lebar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ShareLocation.trackingUserName!,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '''860m - 28min''',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        // Tambahkan fungsi yang ingin dijalankan ketika tombol ditekan di sini
                        // print('Tombol telepon ditekan');
                        final call = Uri.parse('tel:+91 9830268966');
                        if (await canLaunchUrl(call)) {
                          launchUrl(call);
                        } else {
                          throw 'Could not launch $call';
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green, // Warna latar belakang lingkaran
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  0.3), // Warna dan opasitas bayangan
                              spreadRadius: 2, // Penyebaran bayangan
                              blurRadius: 4, // Tingkat keburaman bayangan
                              offset: Offset(0,
                                  2), // Posisi bayangan relatif terhadap kontainer
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(
                            8), // Padding untuk jarak antara ikon dan tepi lingkaran
                        child: Icon(
                          Icons.phone, // Menggunakan ikon telepon
                          color: Colors.white, // Warna ikon menjadi putih
                          size: 24, // Ukuran ikon
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text("Monumen Nasional"),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: Icon(Icons.double_arrow),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(ShareLocation.trackingDestinationLocationName!
                        .split(",")
                        .first),
                  ),
                ),
              ],
            ),
          ),
          buildAboutText(context),
          SizedBox(height: 24),
        ],
      );

  Widget buildAboutText(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showBottomSheet(context);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width *
              0.32, // Padding kiri menjadi 10% dari lebar layar
          MediaQuery.of(context).size.height *
              0, // Padding atas menjadi 10% dari tinggi layar
          MediaQuery.of(context).size.width *
              0, // Padding kanan menjadi 10% dari lebar layar
          MediaQuery.of(context).size.height *
              0, // Padding bawah menjadi 10% dari tinggi layar
        ),
        child: Text(
          'Show Details',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
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
                              // ElevatedButton(
                              //     onPressed: () {
                              //       shareLocation();
                              //     },
                              //     child: Icon(Icons.share)),
                              // SizedBox(
                              //   width: 5,
                              // ),
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

  // void _showBottomSheet(BuildContext context) {
  //   Map<String, dynamic> totals = _calculateTotals(MapPage.allSteps);

  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (BuildContext context) {
  //       return Container(
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Padding(
  //               padding: EdgeInsets.all(20),
  //               child: RichText(
  //                 text: TextSpan(
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.black,
  //                   ),
  //                   children: [
  //                     TextSpan(
  //                       text: '${totals['totalDuration']} mins ',
  //                     ),
  //                     TextSpan(
  //                       text:
  //                           '(${totals['totalDistance'].toStringAsFixed(2)} km)',
  //                       style: TextStyle(color: Colors.grey),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             Expanded(
  //               child: ListView.builder(
  //                 itemCount: MapPage.allSteps.length,
  //                 itemBuilder: (context, index) {
  //                   var step = MapPage.allSteps[index];
  //                   return ListTile(
  //                     contentPadding:
  //                         EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //                     title: Text(
  //                       step['instructions'],
  //                       style: TextStyle(fontWeight: FontWeight.bold),
  //                     ),
  //                     subtitle: Text(
  //                       '${step['distance']} - ${step['duration']}',
  //                       style: TextStyle(color: Colors.grey),
  //                     ),
  //                     leading: CircleAvatar(
  //                       backgroundColor: Colors.blue,
  //                       child: Text(
  //                         '${index + 1}',
  //                         style: TextStyle(color: Colors.white),
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

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

  // Widget buildAboutText() {
  //   final routeSteps = [
  //     {
  //       'icon': Icons.person_pin_circle,
  //       'title': 'Lokasi awal - 3.2 km',
  //       'subtitle': 'Waktu tempuh: 35 menit',
  //     },
  //     {
  //       'icon': Icons.turn_right,
  //       'title': 'Belok kanan - Jalan kaki - 1.2 km',
  //       'subtitle': 'Waktu tempuh: 15 menit',
  //     },
  //     {
  //       'icon': Icons.straight,
  //       'title': 'Lurus - Jalan kaki - 1.5 km',
  //       'subtitle': 'Waktu tempuh: 20 menit',
  //     },
  //     {
  //       'icon': Icons.turn_left,
  //       'title': 'Belok kiri - Jalan kaki - 1.8 km',
  //       'subtitle': 'Waktu tempuh: 25 menit',
  //     },
  //     {
  //       'icon': Icons.location_on,
  //       'title': 'Tiba di Plaza Indonesia',
  //     },
  //   ];

  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 24),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: <Widget>[
  //         Center(
  //           child: Text(
  //             'Rute',
  //             style: TextStyle(fontWeight: FontWeight.w600),
  //           ),
  //         ),
  //         SizedBox(height: 12),
  //         Center(
  //           child: Text(
  //             'Monumen Nasional ke Plaza Indonesia:',
  //             style: TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //         SizedBox(height: 8),
  //         ...routeSteps.map<Widget>((step) {
  //           return Column(
  //             children: [
  //               ListTile(
  //                 leading:
  //                     Icon(step['icon'] as IconData), // Konversi ke IconData
  //                 title: Text(step['title'] as String), // Konversi ke String
  //                 subtitle: step['subtitle'] != null
  //                     ? Text(step['subtitle'] as String)
  //                     : null, // Konversi ke String
  //               ),
  //               Divider(),
  //             ],
  //           );
  //         }).toList(),
  //       ],
  //     ),
  //   );
  // }

  Widget buildDragHandle() => GestureDetector(
        child: Center(
          child: Container(
            width: 30,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        onTap: togglePanel,
      );

  void togglePanel() => panelController.isPanelOpen
      ? panelController.close()
      : panelController.open();
}