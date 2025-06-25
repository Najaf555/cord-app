import 'package:flutter/material.dart';

/// Returns a width as a percentage of the screen width.
double screenWidthPct(BuildContext context, double pct) =>
    MediaQuery.of(context).size.width * pct;

/// Returns a height as a percentage of the screen height.
double screenHeightPct(BuildContext context, double pct) =>
    MediaQuery.of(context).size.height * pct;

/// Returns adaptive padding based on screen width.
EdgeInsets adaptivePadding(BuildContext context) {
  double width = MediaQuery.of(context).size.width;
  if (width < 400) {
    return const EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  } else if (width < 600) {
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  } else {
    return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
  }
}
