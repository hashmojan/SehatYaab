import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sehatyab/view/authentication/dr_signup/dr_signup.dart';
import 'package:sehatyab/view/authentication/signup_selection/signup_selectionpage.dart';
import '../../res/colors/app_colors.dart';
import '../authentication/login/login_page.dart';
import '../authentication/patient_signup/patient_signup_page.dart';
import '../home/dr_home/doctor_home_page.dart';
import '../home/patient_home/patient_home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Scale Animation
    _scaleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scaleAnimation =
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack);
    _scaleController.forward();

    // Fade Animation
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // Navigate after animation completes
    Future.delayed(const Duration(seconds: 3), () => checkUserAndRedirect());
  }

  Future<void> checkUserAndRedirect() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Check the 'users' collection for user type
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userType = userDoc.data()?['userType'] as String?;

          if (userType == 'doctor') {
            // Verify doctor exists in doctors collection
            final doctorDoc = await FirebaseFirestore.instance
                .collection('doctors')
                .doc(user.uid)
                .get();

            if (doctorDoc.exists) {
              Get.offAll(() => DoctorHomePage());
            } else {
              // Doctor document missing - treat as new registration
              Get.offAll(() => DoctorSignupPage());
            }
          } else {
            // Verify patient exists in patients collection
            final patientDoc = await FirebaseFirestore.instance
                .collection('patients')
                .doc(user.uid)
                .get();

            if (patientDoc.exists) {
              Get.offAll(() => PatientHomePage());
            } else {
              // Patient document missing - treat as new registration
              Get.offAll(() => PatientSignupPage());
            }
          }
        } else {
          // User document missing - treat as new registration
          Get.offAll(() => SignupSelectionPage());
        }
      } catch (e) {
        print('Error checking user role: $e');
        Get.offAll(() => LoginPage());
      }
    } else {
      Get.offAll(() => LoginPage());
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.stethoscope,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'sehatyab',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Digital Healthcare Companion',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
          // HIPAA compliance badge at bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shieldCheck, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'HIPAA Compliant',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}