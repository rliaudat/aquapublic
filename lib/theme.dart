import 'package:flutter/material.dart';

Color primaryColor = const Color(0xFF156082);
Color secondaryColor = const Color(0xff197ba9);
Color whiteColor = const Color(0xFFFFFFFF);
Color borderColor = const Color(0xff938e8e);
Color greyColor = const Color(0xffefefef);
Color darkGreyColor = const Color(0xff565555);
Color blackColor = const Color(0xff000000);
Color blueColor = const Color(0xffbfd7ff);
Color textColor = const Color(0xFFc1d3dc);


Color transparentColor =  Colors.transparent;
Color orangeColor =  Colors.orangeAccent;
Color redColor =  const Color.fromARGB(255, 241, 4, 55);
Color greenColor =  Colors.green;
Color darkOrangeColor =  Colors.orange;
Color backgroundColor = const Color(0xFFF0F3F8);



// Paddings
double p = 12;

// Margins
double m = 10;

// Radius (as requested)
double radius = 12;

// Screen Dimensions
double width(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double height(BuildContext context) {
  return MediaQuery.of(context).size.height;
}