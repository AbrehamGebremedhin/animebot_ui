import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.tealAccent;
  static const Color secondaryColor = Colors.pinkAccent;

  static BoxDecoration backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withOpacity(0.7),
        Colors.black.withOpacity(0.5),
      ],
    ),
  );

  static Widget backgroundContainer({required Widget child}) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/anime_background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          decoration: backgroundDecoration,
        ),
        child,
      ],
    );
  }
}
