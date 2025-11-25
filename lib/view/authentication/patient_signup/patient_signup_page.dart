import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sehatyab/res/routes/routes_name.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/input_field.dart';
import '../../../res/components/round_button.dart';
import '../../../res/device_size/device_size.dart';
import '../../../view_model/controller/authentication_controller/patient_signup_view_model.dart';

class PatientSignupPage extends StatefulWidget {
  const PatientSignupPage({super.key});

  @override
  State<PatientSignupPage> createState() => _PatientSignupPageState();
}

class _PatientSignupPageState extends State<PatientSignupPage> with SingleTickerProviderStateMixin {
  final _formkey = GlobalKey<FormState>();
  late AnimationController _animationController;
  final patientSignupVM = Get.put(PatientSignupViewModel());
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withOpacity(0.95),
              AppColors.secondaryColor.withOpacity(0.95),
              Colors.blue.shade900.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: isWeb
                      ? Container(
                    width: 500,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: _buildPatientSignupForm(context),
                  )
                      : _buildPatientSignupForm(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSignupForm(BuildContext context) {
    return Form(
      key: _formkey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _animationController,
              curve: Curves.elasticOut,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    LucideIcons.heart,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Start Your Health Journey',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your patient account and access quality healthcare',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: height * .04),

          // Personal Information Section
          _buildSectionHeader('Personal Information'),
          SizedBox(height: height * .02),

          _buildAnimatedInputField(
            index: 0,
            controller: patientSignupVM.nameController,
            hintText: 'Full Name',
            icon: LucideIcons.user,
            validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
          ),

          SizedBox(height: height * .02),

          // Contact Information Section
          _buildSectionHeader('Contact Information'),
          SizedBox(height: height * .02),

          _buildAnimatedInputField(
            index: 1,
            controller: patientSignupVM.phoneController,
            hintText: 'Phone Number (e.g., 03001234567)',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value!.isEmpty || !RegExp(r'^03\d{9}$').hasMatch(value)) {
                return 'Invalid phone number (e.g., 03xxxxxxxxx)';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),

          _buildAnimatedInputField(
            index: 2,
            controller: patientSignupVM.emailController,
            hintText: 'Email Address',
            icon: LucideIcons.mail,
            validator: (value) {
              if (value!.isEmpty || !value.isEmail) {
                return 'Invalid email address';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),

          _buildAnimatedInputField(
            index: 3,
            controller: patientSignupVM.passwordController,
            hintText: 'Password',
            icon: LucideIcons.lock,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),

          SizedBox(height: height * .02),

          // Location Information Section
          _buildSectionHeader('Location Information'),
          SizedBox(height: height * .02),

          _buildAnimatedInputField(
            index: 4,
            controller: patientSignupVM.cityController,
            hintText: 'City',
            icon: LucideIcons.mapPin,
            validator: (value) => value!.isEmpty ? 'Please enter your city' : null,
          ),

          SizedBox(height: height * .02),

          // Gender Selection
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
            )),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gender',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Row(
                    children: [
                      _buildGenderOption(
                        value: 'male',
                        label: 'Male',
                        icon: LucideIcons.user,
                        isSelected: patientSignupVM.gender.value == 'male',
                        onTap: () => patientSignupVM.gender.value = 'male',
                      ),
                      const SizedBox(width: 16),
                      _buildGenderOption(
                        value: 'female',
                        label: 'Female',
                        icon: LucideIcons.user,
                        isSelected: patientSignupVM.gender.value == 'female',
                        onTap: () => patientSignupVM.gender.value = 'female',
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ),

          SizedBox(height: height * .04),

          // Sign Up Button
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
            ),
            child: Obx(() => RoundButton(
              title: 'CREATE PATIENT ACCOUNT',
              width: double.infinity,
              buttonColor: Colors.white,
              textColor: AppColors.primaryColor,
              onPress: () {
                if (_formkey.currentState!.validate()) {
                  patientSignupVM.loading.value = true;
                  // Implement your patient signup logic here using patientSignupVM
                  print('Name: ${patientSignupVM.nameController.value.text}');
                  print('Phone: ${patientSignupVM.phoneController.value.text}');
                  print('Email: ${patientSignupVM.emailController.value.text}');
                  print('Password: ${patientSignupVM.passwordController.value.text}');
                  print('City: ${patientSignupVM.cityController.value.text}');
                  print('Gender: ${patientSignupVM.gender.value}');
                  patientSignupVM.signUpPatient();
                }
              },
              loading: patientSignupVM.loading.value,
            )),
          ),

          SizedBox(height: height * .03),

          // Login Link
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.9, 1.0),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have a Patient Account? ",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(RouteName.loginPage),
                    child: Text(
                      'Login Here',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
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

  Widget _buildSectionHeader(String title) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      )),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAnimatedInputField({
    required int index,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.1 + (index * 0.1), 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.1 + (index * 0.1), 1.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InputField(
            controller: controller,
            fillColor: Colors.white.withOpacity(0.15),
            errorcolor: Colors.orange.shade300,
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
            prefixIconWidth: 80.0,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String value,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}