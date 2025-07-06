import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import '../globals.dart';
import '../shared_components/calendar_picker.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _dateOfBirthController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showCustomDatePicker(
      context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dateOfBirthController.text =
            "${pickedDate.day} / ${pickedDate.month} / ${pickedDate.year}";
      });
    }
  }

  void _signUp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authService = AuthService();
      try {
        final response = await authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          mobileNumber: _mobileNumberController.text,
          dateOfBirth: _dateOfBirthController.text,
        );
        if (response.user != null) {
          // Sign-up successful, navigate to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          // Handle sign-up failure
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-up failed. Please try again.')),
          );
        }
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Create Account",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: const BoxDecoration(
                    color: OffWhite,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50)),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _fullNameController,
                          label: "Full Name",
                          hint: "Enter your name",
                          validator: (value) =>
                              value!.isEmpty ? "This field is required" : null,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                          hint: "example@example.com",
                          validator: (value) => value!.isEmpty
                              ? "This field is required"
                              : EmailValidator.validate(value)
                                  ? null
                                  : "Enter a valid email",
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _mobileNumberController,
                          label: "Mobile Number",
                          hint: "+123 456 789",
                          validator: (value) =>
                              value!.isEmpty ? "This field is required" : null,
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _dateOfBirthController,
                              label: "Date Of Birth",
                              hint: "DD / MM / YYYY",
                              validator: (value) => value!.isEmpty
                                  ? "This field is required"
                                  : null,
                              suffixIcon: Icon(Icons.calendar_today,
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _passwordController,
                          label: "Password",
                          hint: "********",
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onVisibilityToggle: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          validator: (value) =>
                              value!.isEmpty ? "This field is required" : null,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: "Confirm Password",
                          hint: "********",
                          isPassword: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          onVisibilityToggle: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                          validator: (value) => value!.isEmpty
                              ? "This field is required"
                              : value == _passwordController.text
                                  ? null
                                  : "Passwords do not match",
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "By continuing, you agree to",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          "Terms of Use and Privacy Policy.",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _signUp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginScreen()));
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Already have an account? ",
                                style: const TextStyle(
                                    color: secondaryColor,
                                    fontSize: 16,
                                    fontFamily: 'Poppins'),
                                children: [
                                  TextSpan(
                                    text: "Log In",
                                    style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  bool isPassword = false,
  bool isPasswordVisible = false,
  VoidCallback? onVisibilityToggle,
  required String? Function(String?)? validator,
  Widget? suffixIcon, // Add suffixIcon parameter
}) {
  return TextFormField(
    controller: controller,
    obscureText: isPassword ? !isPasswordVisible : false,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: softBlue,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onVisibilityToggle,
            )
          : suffixIcon,
    ),
    validator: validator,
  );
}