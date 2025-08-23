import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/routes/routes_name.dart';

class SignupSelectionPage extends StatefulWidget {
  const SignupSelectionPage({super.key});

  @override
  State<SignupSelectionPage> createState() => _SignupSelectionPageState();
}

class _SignupSelectionPageState extends State<SignupSelectionPage> {
  String _userType = 'patient';

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account As',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildUserTypeCard(
                    context,
                    type: 'patient',
                    title: 'Patient',
                    icon: Icons.person,
                    description: 'Sign up to book appointments and manage your health records',
                  ),
                  SizedBox(height: 20),
                  _buildUserTypeCard(
                    context,
                    type: 'doctor',
                    title: 'Doctor',
                    icon: Icons.medical_services,
                    description: 'Sign up to manage your practice and appointments',
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('Selected user type: $_userType');

                      if (_userType == 'doctor') {
                        debugPrint('Navigating to doctor signup');
                        Get.toNamed(RouteName.doctorSignup);
                      } else {
                        debugPrint('Navigating to patient signup');
                        Get.toNamed(RouteName.patientSignup);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(BuildContext context, {
    required String type,
    required String title,
    required IconData icon,
    required String description,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _userType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _userType == type
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: _userType == type
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: type,
              groupValue: _userType,
              onChanged: (String? value) {
                setState(() {
                  _userType = value!;
                });
              },
              activeColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}