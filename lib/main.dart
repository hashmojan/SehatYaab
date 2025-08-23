import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import the provider package

// Make sure these import paths are correct for your project
import 'package:sehatyab/res/colors/app_colors.dart';
import 'package:sehatyab/res/routes/routes.dart';
import 'package:sehatyab/res/routes/routes_name.dart';
// If AppointmentDiaryPage is not your initial route from initialRoute,
// then having it as 'home' might be redundant. Removed it for clarity.
// import 'package:sehatyab/view/doctor/appointment/appointment_diary.dart';
import 'package:sehatyab/view_model/controller/appointment_controller/doctor_controller/doctor_appointment_controller.dart';
// Note: DoctorScheduleController is likely a GetX controller, distinct from DoctorScheduleProvider (a Provider package ChangeNotifier)
// If you use both, ensure they manage distinct state or serve different purposes.
// import 'package:sehatyab/view_model/controller/appointment_controller/schedule_controller/doctor_schedule_controller.dart';

// THIS IS THE KEY IMPORT FOR THE PROVIDER PACKAGE
import 'package:sehatyab/view_model/controller/appointment_controller/schedule_controller/doctor_schedule_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter engine is initialized

  // Initialize Firebase App
  // You might need to configure options for different platforms
  // e.g., Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // Initialize ThemeController using GetX
  final themeController = ThemeController();
  Get.put(themeController); // Register ThemeController globally with GetX

  // Load theme preference from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;
  themeController.setTheme(isDarkMode); // Set initial theme based on preference

  runApp(const MyApp());
}

// GetX Controller for Theme Management
class ThemeController extends GetxController {
  var isDarkMode = false.obs; // Observable boolean for theme mode

  // Method to set theme (used on app start)
  void setTheme(bool darkMode) {
    isDarkMode.value = darkMode;
    Get.changeThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
    if (kDebugMode) {
      print('Theme set to: ${darkMode ? 'Dark' : 'Light'}');
    }
  }

  // Method to toggle theme (and save preference)
  Future<void> toggleTheme(bool darkMode) async {
    isDarkMode.value = darkMode;
    Get.changeThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
    if (kDebugMode) {
      print('Theme toggled to: ${darkMode ? 'Dark' : 'Light'} and saved');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider is used to register all your 'provider' package based providers.
    // It must wrap the top-level widget that needs access to these providers (e.g., GetMaterialApp).
    return MultiProvider(
      providers: [
        // Register DoctorScheduleProvider using ChangeNotifierProvider
        // The 'create' method is called once to create the instance.
        ChangeNotifierProvider<DoctorScheduleProvider>(
          create: (context) => DoctorScheduleProvider(),
        ),
        // Add other ChangeNotifierProviders here if you have more using the 'provider' package
        // Example: ChangeNotifierProvider<AnotherProvider>(create: (context) => AnotherProvider()),
      ],
      // GetMaterialApp is your top-level widget for GetX routing and theme management.
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false, // Set to true for debug banner
        title: "sehatyab",

        // Theme configurations
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        // GetX theme mode management: retrieves the current theme mode from ThemeController
        themeMode: Get.find<ThemeController>().isDarkMode.value ? ThemeMode.dark : ThemeMode.light,

        // Initial routing and pages
        initialRoute: RouteName.splashScreen, // Your application's starting route
        getPages: AppRoutes.routes, // Define your routes with GetX

        // Initial bindings for GetX controllers that need to be available early
        initialBinding: BindingsBuilder(() {
          // Register your GetX controllers here
          Get.put(DoctorAppointmentController());
          // If you have a DoctorScheduleController (GetX), put it here:
          // Get.put(DoctorScheduleController());
        }),

        // The 'home' property should generally not be used when 'initialRoute' is defined,
        // as it will override the initialRoute. Remove it to ensure routing works as expected.
        // home: AppointmentDiaryPage(),
      ),
    );
  }

  // Light Theme Definition
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme), // Apply Poppins to light theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightPrimary,
        elevation: 2,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: AppColors.lightSecondary,
        textTheme: ButtonTextTheme.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) return AppColors.lightPrimary;
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) return AppColors.lightPrimary.withOpacity(0.5);
          return Colors.grey.withOpacity(0.5);
        }),
      ),
      // Add other light theme properties as needed
    );
  }

  // Dark Theme Definition
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: Colors.black,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme), // Apply Poppins to dark theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkPrimary,
        elevation: 2,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.green, // Consider using AppColors.darkSecondary if defined
        textTheme: ButtonTextTheme.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) return AppColors.darkSecondary;
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) return AppColors.darkSecondary.withOpacity(0.5);
          return Colors.grey.withOpacity(0.5);
        }),
      ),
      // Add other dark theme properties as needed
    );
  }
}