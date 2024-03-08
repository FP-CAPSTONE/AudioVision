import 'package:flutter/material.dart';

class NowNavigationTextWidget extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool bold; // Add bold parameter
  final Color? color; // Add color parameter

  const NowNavigationTextWidget({super.key, 
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

Widget buildArrowDirectionContainer(String iconName, {Color? color}) {
  return Container(
    margin: const EdgeInsets.only(right: 8.0),
    child: Icon(
      _getIconData(iconName), // Helper function to get IconData from icon name
      size: 30.0,
      color: color ?? Colors.white, // Use provided color or default to white
    ),
  );
}

IconData _getIconData(String iconName) {
  switch (iconName) {
    case 'arrow_forward':
      return Icons.arrow_forward;
    case 'arrow_back':
      return Icons.arrow_back;
    case 'arrow_upward':
      return Icons.arrow_upward;
    case 'arrow_downward':
      return Icons.arrow_downward;
    case 'arrow_back_ios':
      return Icons.arrow_back_ios;
    case 'arrow_forward_ios':
      return Icons.arrow_forward_ios;
    case 'close':
      return Icons.close;
    case 'call_split':
      return Icons.call_split;
    // Add more cases for other arrow icons as needed
    default:
      return Icons
          .arrow_forward; // Default to arrow_forward if icon name is not recognized
  }
}
