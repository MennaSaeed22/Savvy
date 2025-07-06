import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:savvy/screens/globals.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_header.dart';
import 'delete_success.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool isVisible = false;
  bool isLoading = false;
  final _keyForm = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  String? passwordError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performCompleteLogout(BuildContext context) async {
    try {
      // Clear all Riverpod providers/state management data
      // Clear user provider cache (sets state to loading)
      ref.read(userProvider.notifier).clearCache();
      ref.read(transactionProvider.notifier).clearCache();
      ref.read(financialSummaryProvider.notifier).clearCache();
      // Add other providers as needed
      
      // Clear any shared preferences or local storage if needed
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.clear();
      
      // Sign out from Supabase
      final authService = AuthService();
      await authService.signOut();

      // Note: Navigation to onboarding is now handled by the success screen
    } catch (e) {
      // Even if logout fails, the success screen will still navigate to onboarding
      print('Error during logout: $e');
    }
  }

  void _handleAccountDeletion() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      passwordError = null;
    });

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final userId = user?.id;

    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        passwordError = "Password is required to proceed.";
        isLoading = false;
      });
      return;
    }

    try {
      // Get the current session token
      final session = supabase.auth.currentSession;
      if (session != null) {
        final response = await http.delete(
          Uri.parse('$baseURL/Users/delete-account'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
          },
          body: json.encode({
            'user_id': userId,
            'password': _passwordController.text,
          }),
        );

        final responseData = json.decode(response.body);
        if (response.statusCode == 200) {
          // Success - account deleted
          setState(() {
            isLoading = false;
          });

          // Clear all provider data and perform logout immediately
          await _performCompleteLogout(context);

          if (mounted) {
            // Navigate to success screen (which will handle onboarding navigation)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AccountDeletionSuccessScreen(),
              ),
            );
          }
        } else if (response.statusCode == 400) {
          // Bad request - likely incorrect password
          setState(() {
            passwordError = responseData['error'] ?? "Incorrect password.";
            isLoading = false;
          });
        } else if (response.statusCode == 401) {
          // Unauthorized
          setState(() {
            passwordError = "Authentication failed.";
            isLoading = false;
          });
        } else {
          // Other errors
          throw Exception(responseData['error'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('No active session');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: OffWhite,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Confirm Deletion",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Are you absolutely sure you want to delete your account? This action cannot be undone.",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: softBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 70, vertical: 14),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                            _handleAccountDeletion();
                          },
                    style: TextButton.styleFrom(
                      backgroundColor: isLoading ? Colors.grey : Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 70, vertical: 14),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: OffWhite,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            AppHeader(title: "Delete Account"),
            const SizedBox(height: 20),
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        "Are You Sure You Want To Delete Your Account?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: softBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "This action will permanently delete all of your data, and you will not be able to recover it. Please keep the following in mind before proceeding:",
                              style: TextStyle(color: Colors.black87),
                            ),
                            SizedBox(height: 12),
                            Text(
                                "• All your expenses, income and associated transactions will be eliminated."),
                            SizedBox(height: 8),
                            Text(
                                "• You will not be able to access your account or any related information."),
                            SizedBox(height: 8),
                            Text("• This action cannot be undone."),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Please Enter Your Password To Confirm Deletion Of Your Account.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _keyForm,
                        child: Column(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: softBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: !isVisible,
                                enabled: !isLoading,
                                onChanged: (value) {
                                  if (passwordError != null) {
                                    setState(() {
                                      passwordError = null;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Password",
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              isVisible = !isVisible;
                                            });
                                          },
                                  ),
                                ),
                              ),
                            ),
                            if (passwordError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  passwordError!,
                                  style: TextStyle(
                                    color:
                                        const Color.fromARGB(255, 172, 35, 25),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_passwordController.text.isEmpty) {
                                  setState(() {
                                    passwordError =
                                        "Password is required to proceed.";
                                  });
                                } else {
                                  setState(() {
                                    passwordError = null;
                                  });
                                  _showConfirmationDialog();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLoading ? Colors.grey : primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                "Delete Account",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: OffWhite,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        style: TextButton.styleFrom(
                          backgroundColor: softBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 70, vertical: 14),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}