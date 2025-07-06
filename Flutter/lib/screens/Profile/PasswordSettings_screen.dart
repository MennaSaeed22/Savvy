import 'package:flutter/material.dart';
import 'package:savvy/widgets/app_header.dart';
import 'success_delay.dart';
import '../globals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordSettingsScreen extends StatefulWidget {
  @override
  _PasswordSettingsScreenState createState() => _PasswordSettingsScreenState();
}

class _PasswordSettingsScreenState extends State<PasswordSettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              AppHeader(title: "Change Password"),
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
                        _buildPasswordField(
                          label: 'Current Password',
                          hint: 'Enter current password',
                          controller: _currentPasswordController,
                          visible: _showCurrent,
                          toggleVisibility: () {
                            setState(() => _showCurrent = !_showCurrent);
                          },
                          errorText: _currentPasswordError,
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          label: 'New Password',
                          hint: 'Enter new password',
                          controller: _newPasswordController,
                          visible: _showNew,
                          toggleVisibility: () {
                            setState(() => _showNew = !_showNew);
                          },
                          errorText: _newPasswordError,
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          label: 'Confirm New Password',
                          hint: 'Re-enter new password',
                          controller: _confirmPasswordController,
                          visible: _showConfirm,
                          toggleVisibility: () {
                            setState(() => _showConfirm = !_showConfirm);
                          },
                          errorText: _confirmPasswordError,
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _handleChangePassword,
                          child: const Text(
                            "Change Password",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: OffWhite,
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
      ),
    );
  }

  void _handleChangePassword() async {
    setState(() {
      _currentPasswordError = _currentPasswordController.text.isEmpty
          ? 'Please enter your current password'
          : null;
        
      _newPasswordError = _newPasswordController.text.isEmpty
          ? 'Please enter a new password'
          : null;
      
      _confirmPasswordError = _confirmPasswordController.text.isEmpty
          ? 'Please confirm your new password'
          : _confirmPasswordController.text != _newPasswordController.text
              ? 'Passwords do not match'
              : null;
    });
    
    if (_currentPasswordError == null &&
        _newPasswordError == null &&
        _confirmPasswordError == null) {
      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
          return;
        }
        
        // Update password in Supabase
        await supabase.auth.updateUser(
          UserAttributes(password: _newPasswordController.text),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SuccessScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
      }
    }
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback toggleVisibility,
    required String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: softBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: controller,
            obscureText: !visible,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: const TextStyle(color: Colors.black45),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  visible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black54,
                ),
                onPressed: toggleVisibility,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(color: Color.fromARGB(255, 177, 24, 24), fontSize: 12),
          ),
        ],
      ],
    );
  }
}
