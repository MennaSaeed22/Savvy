import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savvy/screens/Analytics/presentation/providers/analytics_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import '../globals.dart';

class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              AppHeader(title: "Profile", arrowVisible: false),
              const SizedBox(height: 60),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.81,
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
                        const SizedBox(height: 40),
                        userAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text("Error: $e"),
                          data: (user) => Text(
                            user?['full_name'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildProfileOptions(context, ref), // Pass ref here
                      ],
                    ),
                  ),
                  Positioned(
                    top: -50,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: userAsync.when(
                        loading: () => const AssetImage('assets/images/profile.jpg'),
                        error: (_, __) => const AssetImage('assets/images/profile.jpg'),
                        data: (user) {
                          final avatarUrl = user?['avatar_url'];
                          if (avatarUrl != null && avatarUrl != '') {
                            return NetworkImage(avatarUrl) as ImageProvider;
                          }
                          return const AssetImage('assets/images/profile.jpg');
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//can use Color(0xFF0068FF)
Widget _buildProfileOptions(BuildContext context, WidgetRef ref) {
  final List<Map<String, dynamic>> options = [
    {
      "icon": Icons.person_outlined,
      "title": "Edit Profile",
      "route": '/edit-profile',
    },
    {
      "icon": Icons.settings_outlined,
      "title": "Settings",
      "route": '/settings',
    },
    {
      "icon": Icons.live_help_outlined,
      "title": "Help",
      "route": '/help',
    },
    {
      "icon": Icons.logout_outlined,
      "title": "Logout",
      "route": '/logout',
    },
  ];

  return Column(
    children: List.generate(options.length, (index) {
      final option = options[index];
      final gradientStartColor = primaryColor;
      final gradientEndColor = Colors.blueAccent;

      // Calculate the gradient color for the current button
      final gradientColor = Color.lerp(
        gradientStartColor,
        gradientEndColor,
        index / (options.length - 1),
      );

      return _profileOption(
        option['icon'],
        option['title'],
        gradientColor ?? primaryColor,
        option['route'],
        context,
        ref, // Pass ref here
      );
    }),
  );
}

Widget _profileOption(IconData icon, String title, Color bgColor, String route,
    BuildContext context, WidgetRef ref) {
  return InkWell(
    onTap: () {
      if (route == '/logout') {
        _showLogoutDialog(context, ref); // Pass ref here
      } else {
        Navigator.pushNamed(context, route);
      }
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    ),
  );
}

void _showLogoutDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
        backgroundColor: OffWhite, // Set background color of the dialog
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Logout",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Are you sure you want to Log out?",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Cancel button
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryColor, // Text color
                      backgroundColor: softBlue, // Button background
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600, // Moved here
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      _performLogout(context, ref); // Handle logout process with ref
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: OffWhite, // Text color for logout
                      backgroundColor:
                          primaryColor, // Background color for logout
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      "Logout",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _performLogout(BuildContext context, WidgetRef ref) async {
  final authService = AuthService();

  // Show a loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    },
  );

  try {
    // Sign out from Supabase
    await authService.signOut();

    if (context.mounted) {
      // Navigate to onboarding screen
      Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);

      // Delay to avoid UI flickering
      Future.delayed(const Duration(milliseconds: 100), () {
        // Clear all related caches/providers
        ref.invalidate(userProvider);
        ref.invalidate(transactionProvider);
        ref.invalidate(financialSummaryProvider);
        ref.invalidate(goalsProvider);
        ref.invalidate(financialDataProvider);
        ref.invalidate(budgetProvider);
        ref.invalidate(forecastProvider);
      });
    }
  } catch (e) {
    // Dismiss dialogs and show error
    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}