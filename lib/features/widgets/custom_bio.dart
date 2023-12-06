import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomBio extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const CustomBio({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var style = TextStyle(fontSize: 11, fontWeight: FontWeight.bold);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: style,
          ),
          SizedBox(
            height: 10.0,
          ),
          Container(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                color: color.withAlpha(20),
                blurRadius: 10.0,
                spreadRadius: 1.0,
                offset: const Offset(
                  0.0,
                  0.0,
                ),
              ),
            ]),
            child: Text(
              value.toString(),
              style: style.copyWith(fontSize: 24.0, color: color, fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
