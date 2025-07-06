import 'package:flutter/material.dart';
import '../screens/globals.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  
  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipPath(
        clipper: BottomNavClipper(),
        child: Container(
          height: 70,
          color: softBlue,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_outlined, 0),
              _buildNavItem(Icons.analytics_outlined, 1),
              _buildNavItem(Icons.swap_vertical_circle_outlined, 2),
              _buildNavItem(Icons.layers_outlined, 3),
              _buildNavItem(Icons.person_outline, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selectedIndex == index ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 28,
          color: selectedIndex == index ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class BottomNavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double curveHeight = 65;
    
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.05, size.height - curveHeight, size.width * 0.15, size.height - curveHeight);
    path.lineTo(size.width * 0.85, size.height - curveHeight);
    path.quadraticBezierTo(size.width * 0.95, size.height - curveHeight, size.width, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
