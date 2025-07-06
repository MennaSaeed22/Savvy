import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../globals.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // AppHeader remains fixed at the top
            AppHeader(
              title: "Settings",
              arrowVisible: true,
            ),
            const SizedBox(height: 30), // Adjusted spacing for consistency
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: OffWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSettingsOption(
                      context,
                      Icons.edit_notifications_outlined,
                      "Notification Settings",
                      '/NotificationSettings', // Route for Notification Settings
                    ),
                    _buildSettingsOption(
                      context,
                      Icons.password_outlined,
                      "Password Settings", // Corrected typo for Password Settings
                      '/PasswordSettings', // Route for Password Settings
                    ),
                    _buildSettingsOption(
                      context,
                      Icons.person_remove_outlined,
                      "Delete Account",
                      '/DeleteAccount', // Route for Delete Account
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This method creates each settings option row with an icon, text, and arrow
  Widget _buildSettingsOption(
      BuildContext context, IconData icon, String text, String route) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route); // Navigate to the specified route
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Circular Icon with primaryColor background
                Container(
                  padding:
                      const EdgeInsets.all(7.0), // Adjust size of the circle
                  decoration: BoxDecoration(
                    color: primaryColor, // Background color for the circle
                    shape: BoxShape.circle, // Makes the container circular
                  ),
                  child: Icon(
                    icon,
                    color: OffWhite, // Icon color
                    size: 20, // Adjust icon size
                  ),
                ),
                const SizedBox(width: 15),
                // Text
                Text(
                  text,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor),
                ),
              ],
            ),
            // Arrow Icon
            const Icon(
              Icons.arrow_forward_ios_outlined,
              color: secondaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
