import 'package:flutter/material.dart';

class NowNavigationTextWidget extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool bold; // Add bold parameter
  final Color? color; // Add color parameter

  NowNavigationTextWidget({
    required this.text,
    required this.fontSize,
    this.bold = true, // Default to true
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight:
            bold ? FontWeight.bold : FontWeight.normal, // Check bold parameter
        color: color ?? Colors.white, // Use provided color or default to white
      ),
    );
  }
}

Widget buildArrowDirectionContainer(
    String iconName, String distance, String manuever,
    {Color? color}) {
  return Container(
    height: 60,
    margin: EdgeInsets.only(right: 8.0),
    child: Column(
      children: [
// Helper function to get IconData from icon name
      ],
    ),
  );
}
