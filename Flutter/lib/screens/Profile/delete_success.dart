import 'package:flutter/material.dart';
import 'dart:async';
import '../globals.dart';

class AccountDeletionSuccessScreen extends StatefulWidget {
  @override
  _AccountDeletionSuccessScreenState createState() => _AccountDeletionSuccessScreenState();
}

class _AccountDeletionSuccessScreenState extends State<AccountDeletionSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward(); // Start animation

    // Redirect to onboarding screen after 2 seconds and clear all routes
    Timer(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/onboarding', // Navigate to onboarding
          (route) => false, // Clear all previous routes
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 100,
                color: OffWhite,
              ),
              SizedBox(height: 20),
              Text(
                "Your Account Has Been\nSuccessfully Deleted",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Thank you for using our service",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(OffWhite),
              ),
            ],
          ),
        ),
      ),
    );
  }
}