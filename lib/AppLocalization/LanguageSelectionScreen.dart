// Step 2: Create a language selection screen (language_selection_screen.dart)
import 'package:cropai/Dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _setLanguage(BuildContext context, String languageCode) async {
    // Save selected language to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);

    // Change app locale
    await context.setLocale(Locale(languageCode));

    // Navigate to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
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
                  'assets/images/crop_logo.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome to Crop-AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      
          const SizedBox(height: 40),
      
          const Text(
            'Select your preferred language',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).tr(),
      
          const SizedBox(height: 20),
      
          // English Option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: InkWell(
              onTap: () => _setLanguage(context, 'en'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.language, color: Color(0xFF6B8E23)),
                    SizedBox(width: 15),
                    Text(
                      'English',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),
      
          const SizedBox(height: 20),
      
          // Hindi Option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: InkWell(
              onTap: () => _setLanguage(context, 'hi'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.language, color: Color(0xFF6B8E23)),
                    SizedBox(width: 15),
                    Text(
                      'हिंदी',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),
                      const SizedBox(height: 20),
      
       Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: InkWell(
              onTap: () => _setLanguage(context, 'gu'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.language, color: Color(0xFF6B8E23)),
                    SizedBox(width: 15),
                    Text(
                      'Gujrati (ગુજરાતી)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),
                      const SizedBox(height: 20),
      
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: InkWell(
              onTap: () => _setLanguage(context, 'tl'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.language, color: Color(0xFF6B8E23)),
                    SizedBox(width: 15),
                    Text(
                      'Tamil (தமிழ்)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16),
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