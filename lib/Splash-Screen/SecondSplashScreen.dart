import 'package:flutter/material.dart';
import 'dart:async';

class SecondSplashScreen extends StatefulWidget {
  const SecondSplashScreen({super.key});
  @override
  State<SecondSplashScreen> createState() => _SecondSplashScreenState();
}
class _SecondSplashScreenState extends State<SecondSplashScreen> with SingleTickerProviderStateMixin {
  final bool _isConnected = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Set up animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    // Initialize the app
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Give the splash screen some time to display
    await Future.delayed(const Duration(seconds: 2));
    if (!_isConnected) {
      _showNoInternetDialog();
      return;
    }
}

  void _showNoInternetDialog() {
    if (mounted) {
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 210),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                // crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo positioned 50dp from top
                  Container(
                    width: 500,
                    height: 100,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.green,
                            width: 4
                        ),
                        color: Colors.green,
                        shape: BoxShape.circle
                    ),

                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 20,
                      width: 50,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'THE NEW ERA OF',
                    style:
                    TextStyle(fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown),
                  ),
                  const Text(
                    '🌾 AGRICULTURE',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ],
              ),
            ),
          ),
          // Spacer()
        ],
      ),
    );
  }
}