import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'launch_screen.dart'; // Import the next screen
import '../globals.dart'; // Import the global variables

/// OnboardingScreen displays a series of pages to introduce the app to new users.
/// Users can swipe through the pages or use the "Next" button to navigate.

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0; // Track current page

  final List<String> titles = [
    "Welcome To\nExpense Manager",
    "Are You Ready To\nTake Control Of\nYour Finances?"
  ];

  final List<String> imagePaths = [
    "assets/images/saving.png",
    "assets/images/bank-card.png",
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.hasClients) {
        setState(() {
          currentPage = _controller.page?.round() ?? 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: PageView.builder(
              controller: _controller,
              itemCount: titles.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      titles[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        color: OffWhite,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: OffWhite,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Circular Background with Image
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: 180, // Background circle size
                        height: 180,
                        decoration: const BoxDecoration(
                          color:softBlue, // Background color
                          shape: BoxShape.circle,
                        ),
                      ),
                      Column(
                        children: [
                          Image.asset(
                            imagePaths[currentPage], // Dynamic image
                            width: 150,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 70),
                  SmoothPageIndicator(
                    controller: _controller,
                    count: titles.length,
                    effect: ExpandingDotsEffect(
                      dotColor: Colors.grey,
                      activeDotColor: primaryColor,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                    onDotClicked: (index) {
                      _controller.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: () {
                      if (_controller.hasClients && _controller.page != null) {
                        if (_controller.page! < titles.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeIn,
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LaunchScreen()),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // Button color
                      foregroundColor: Colors.white, // Text color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10), // Button padding
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30), // Rounded corners
                      ),
                      elevation: 5, // Shadow effect
                    ),
                    child: const Text(
                      "Next",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
