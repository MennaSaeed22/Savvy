import 'package:flutter/material.dart';
import 'package:savvy/screens/globals.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final bool arrowVisible;

  const AppHeader({
    Key? key,
    required this.title,
    this.arrowVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Back arrow (left)
            if (arrowVisible)
              Positioned(
                left: 5,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: OffWhite, size: 25),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            // Title (center)
            Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: arrowVisible ? 20 : 25,
                  fontWeight: FontWeight.w700,
                  color: OffWhite,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Notification icon (right, only if arrow is hidden)
            if (!arrowVisible)
              Positioned(
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.circle_notifications,
                      color: OffWhite, size: 30),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
