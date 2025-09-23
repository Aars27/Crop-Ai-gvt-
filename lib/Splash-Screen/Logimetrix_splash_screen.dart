import 'package:flutter/material.dart';

class LogimetrixSplashScreen extends StatefulWidget {
  const LogimetrixSplashScreen({super.key});

  @override
  _LogimetrixSplashScreen createState() => _LogimetrixSplashScreen();

}

class _LogimetrixSplashScreen extends State<LogimetrixSplashScreen>{
@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/cropnet_bg.png'), // Add this image in assets folder
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Logo Positioned at the Top
          Positioned(
            top: 50, // Adjust as needed
            left: 20, // Adjust as needed
            right: 20,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logimetrix_logo.png', // Add this image in assets folder
                  width: 150, // Adjust size as needed
                ),
                const SizedBox(height: 5),
                const Text(
                  "we follow your dreams",
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
