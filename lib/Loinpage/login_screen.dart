import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Dashboard/dashboard_screen.dart';
import 'APIClient.dart';

class LoginScreen extends StatefulWidget {
// final LoginController controller;

  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  // Focus nodes to track focus state
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  Future<void> _login() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('Error: No internet connection');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('no_internet_connection'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        String email = _emailController.text.trim();
        String password = _passwordController.text.trim();
        final response = await APIClient.loginUser(email, password);
        //  print(response);

        if (response.containsKey('token')) {
          // Login successful
          // print('Login successful: ${response['message']}');
          // Save token and user ID in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', response['token']);
          // Store user ID from response
          if (response.containsKey('user')) {
            final user = response['user'];

            if (user['id'] != null) {
              await prefs.setInt('user_id', user['id']);
            }

            if (user['name'] != null) {
              await prefs.setString('user_name', user['name']);
            }

            if (user['email'] != null) {
              await prefs.setString('user_email', user['email']);
            }

            print("printed:${user['email']}- ${user['name']}");
          }
          print('Auth Token: ${response['token']}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'login_successful'.tr()),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else if (response.containsKey('error')) {
          // Login failed - print error and show snackbar
          // print('Login error: ${response['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['error']),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Unexpected response format
          print('Unexpected response format: $response');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('login_failed'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Login Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('an_error_occurred'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with logo and title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(
              color: Color(0xFF6B8E23),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome to Crop-AI'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
               
              ],
            ),
          ),

          // Login Form
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Colors.grey,
                          ),
                          labelText: 'email_id'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color(0xFF6B8E23), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: _passwordFocusNode.hasFocus
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'please_enter_your_email'.tr();
                          }
                          final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'enter_valid_email'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.password,
                            color: Colors.grey,
                          ),
                          labelText: 'password'.tr(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF6B8E23),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color(0xFF6B8E23), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: _emailFocusNode.hasFocus
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'please_enter_your_password'.tr();
                          }
                          if (value.length < 8) {
                            return 'password_length_error'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 45,
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B8E23),
                              minimumSize: const Size(200, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text('login'.tr(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Center(
              child: Text(
            'Powered by Logimetrix Techsolutions Pvt Ltd',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          )),
        ],
      ),
    );
  }
}
