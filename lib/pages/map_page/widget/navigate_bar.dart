import 'package:audiovision/utils/text_utils.dart';
import 'package:flutter/material.dart';

class NavigateBarWidget extends StatelessWidget {
  final String navigationText;
  const NavigateBarWidget({super.key, required this.navigationText});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.0, left: 8.0, right: 8.0),
      padding: EdgeInsets.all(12.0), // Adjust the padding as needed
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Color.fromARGB(255, 50, 116, 45),
      ),
      child: Row(
        children: [
          buildArrowDirectionContainer('arrow_upward'),
          Expanded(
            child:
                NowNavigationTextWidget(text: navigationText, fontSize: 18.0),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.mic,
              color: Colors.blue[400],
            ),
          ),
        ],
      ),
    );
    ;
  }
}
