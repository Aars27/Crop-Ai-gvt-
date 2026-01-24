
import 'package:cropai/Splash-Screen/splash_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ActivityMonitoring/Activity_Monitoring.dart';
import 'HistoryActivityData/HistoryRequestData.dart';
import 'Arealeveling/AreaLevelingScreen.dart';
import 'Crop-Protection/CropProtection.dart';
import 'Fertilize/Fertilizer_Soil_Treatment.dart';
import 'Harvest/Harvesting_Updates.dart';
import 'Hey-Making/Hay_Making.dart';
import 'Inter-Culture/InterCulture.dart';
import 'AppLocalization/LanguageSelectionScreen.dart';
import 'Land-preparation/Land_Preperation.dart';
import 'Notification/NotificationPage.dart';
import 'Post-Irrigation/Post_Irrigation.dart';
import 'Pre-Irrigation/Pre_Irrigation.dart';
import 'Preland-Peration/Pre_Land_Preperation.dart';
import 'Splash-Screen/SecondSplashScreen.dart';
import 'Silage-Makeing/Silage_Making.dart';
import 'Showing/Sowing.dart';
import 'Loinpage/login_screen.dart';
import 'Dashboard/dashboard_screen.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi'),Locale('gu'),Locale('tl')],
      path: 'assets/translations', // Path to translation files
      fallbackLocale: const Locale('en'),
      child: const CropAI(),
    ),
  );
}

class CropAI extends StatelessWidget {
  const CropAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop-AI',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        primaryColor: const Color(0xFF76A937),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF76A937),
          secondary: const Color(0xFF76A937),
        ),
      ),
      
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/secondplashscreen':(context) => const SecondSplashScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/Arealevelingscreen': (context) => const Arealevelingscreen(),
        '/Pre_Land_Preperation': (context) => const Pre_Land_Preperation(),
        '/Pre_Irrigation': (context) => const Pre_Irrigation(),
        '/Land_Preperation': (context) => const Land_Preperation(),
        '/Sowing': (context) => const Sowing(),
        '/PostIrrigation': (context) => const PostIrrigation(),
        '/FertilizerSoilTreatment': (context) => const FertilizerSoilTreatment(),
        '/Interculture': (context) => const Interculture(),
        '/Cropprotection': (context) => const Cropprotection(),
        '/Activity_Monitoring': (context) => const Activity_Monitoring(),
        '/Harvesting_Updates': (context) => const Harvesting_Updates(),
        '/Hay_Making': (context) => const Hay_Making(),
        '/Silage_Making': (context) => const Silage_Making(),
        '/NotificationPage': (context) => const NotificationPage(),
        '/AgricultureSummaryPage': (context) =>  const FilterFormPage(),
      },
    );
  }
}





