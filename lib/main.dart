import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Your app's local imports
import 'package:sehatyab/res/colors/app_colors.dart';
import 'package:sehatyab/res/routes/routes.dart';
import 'package:sehatyab/res/routes/routes_name.dart';
import 'package:sehatyab/view_model/controller/appointment_controller/doctor_controller/doctor_availability_controller.dart';
import 'package:sehatyab/view_model/controller/home_controller/doctor_home_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize ThemeController
  final themeController = ThemeController();
  Get.put(themeController);

  // Load theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;
  themeController.setTheme(isDarkMode);

  // Pre-initialize the DoctorDailyAvailabilityController before the app starts.
  // This is crucial to ensure the listener is active from the beginning.
  Get.put(DoctorDailyAvailabilityController());

  runApp(const MyApp());
}

// GetX Controller for Theme Management
class ThemeController extends GetxController {
  var isDarkMode = false.obs;

  void setTheme(bool darkMode) {
    isDarkMode.value = darkMode;
    Get.changeThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
    if (kDebugMode) {
      print('Theme set to: ${darkMode ? 'Dark' : 'Light'}');
    }
  }

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
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "sehatyab",

      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: Get.find<ThemeController>().isDarkMode.value ? ThemeMode.dark : ThemeMode.light,

      initialRoute: RouteName.splashScreen,
      getPages: AppRoutes.routes,

      // Correctly register all permanent controllers in a single binding
      initialBinding: BindingsBuilder(() {
        // The availability controller is now initialized in main(), so no need to put it here.
        Get.put(DoctorHomeViewModel());
      }),
    );
  }

  // Light Theme Definition
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
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
    );
  }

  // Dark Theme Definition
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: Colors.black,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
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
        buttonColor: Colors.green,
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
    );
  }
}