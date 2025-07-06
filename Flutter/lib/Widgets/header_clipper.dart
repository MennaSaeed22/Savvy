// lib/widgets/appbar_clipper.dart
import 'package:flutter/material.dart';

class AppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.1, size.height - 30,
        size.width * 0.25, size.height - 30);
    path.lineTo(size.width * 0.75, size.height - 30);
    path.quadraticBezierTo(
        size.width * 0.9, size.height - 30, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
