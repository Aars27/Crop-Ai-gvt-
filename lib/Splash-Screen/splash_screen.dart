import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../widget/PermissionService.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _isConnected = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    // Give the splash screen some time to display
    await Future.delayed(const Duration(seconds: 2));

    // Check internet connectivity
    await _checkConnectivity();

    if (!_isConnected) {
      _showNoInternetDialog();
      return;
    }

    // Request permissions
    await _requestPermissions();

    // Check if user is logged in
    await _checkAuthentication();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  Future<void> _requestPermissions() async {
    await PermissionService().requestPermissions();
  }

  Future<void> _checkAuthentication() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        _navigateToDashboard();
      } else {
         _navigateToLogin();
      }
    } catch (e) {
      print('Error checking authentication: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
       Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _showNoInternetDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text(
            'Please check your internet connection and try again.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeApp();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleButtonPress() {
    if (_isConnected) {
      _initializeApp();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/cropnet_bg.png',
            fit: BoxFit.cover,
          ),

          // Content with fade animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 140),

                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      // padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        // fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title text
                    const Text(
                      'THE NEW ERA OF',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      '🌾 AGRICULTURE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 1.0,
                      ),
                    ),

                    // Spacer to push button to bottom
                    const Spacer(),

                    // Bottom button
                    // Container(
                    //   width: 200,
                    //   height: 50,
                    //   margin: const EdgeInsets.only(bottom: 40),
                    //   child: ElevatedButton(
                    //     onPressed: _isConnected ? _handleButtonPress : null,
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.white,
                    //       foregroundColor: Colors.black,
                    //       elevation: 8,
                    //       shadowColor: Colors.black.withOpacity(0.3),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(16),
                    //       ),
                    //       disabledBackgroundColor: Colors.grey.shade300,
                    //       disabledForegroundColor: Colors.grey.shade600,
                    //     ),
                    //     child: Text(
                    //       _isConnected ? 'Get Started' : 'No Connection',
                    //       style: const TextStyle(
                    //         fontSize: 18,
                    //         fontWeight: FontWeight.w500,
                    //         letterSpacing: 0.5,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}