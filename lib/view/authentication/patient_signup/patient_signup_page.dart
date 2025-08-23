import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sehatyab/res/routes/routes_name.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/input_field.dart';
import '../../../res/components/round_button.dart';
import '../../../res/device_size/device_size.dart';
import '../../../view_model/controller/authentication_controller/patient_signup_view_model.dart'; // Assuming you'll create this

class PatientSignupPage extends StatefulWidget {
  const PatientSignupPage({super.key});

  @override
  State<PatientSignupPage> createState() => _PatientSignupPageState();
}

class _PatientSignupPageState extends State<PatientSignupPage> with SingleTickerProviderStateMixin {
  final _formkey = GlobalKey<FormState>();
  late AnimationController _animationController;
  final patientSignupVM = Get.put(PatientSignupViewModel()); // Initialize the patient signup view model

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
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
              padding: const EdgeInsets.all(10.0),
              child: isWeb
                  ? Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildPatientSignupForm(context),
              )
                  : _buildPatientSignupForm(context),
            ),
          ),
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
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutBack,
            ),
            child: Center(
              child: Text(
                'Patient Sign Up',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: patientSignupVM.nameController,
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'Name',
            prefixIcon: const Icon(
              LucideIcons.user,
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            validator: (String? value) {
              if (value!.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: patientSignupVM.phoneController,
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'eg. 03001234567',
            prefixIcon: const Icon(
              LucideIcons.phone,
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            keyboardType: TextInputType.phone,
            validator: (String? value) {
              if (value!.isEmpty || !RegExp(r'^03\d{9}$').hasMatch(value)) {
                return 'Invalid phone number (e.g., 03xxxxxxxxx)';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: patientSignupVM.emailController,
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'Email',
            prefixIcon: const Icon(
              LucideIcons.mail,
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            validator: (String? value) {
              if (value!.isEmpty || !value.isEmail) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: patientSignupVM.passwordController,
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'Password',
            obscureText: true,
            prefixIcon: const Icon(
              LucideIcons.lock,
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            validator: (String? value) {
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
          InputField(
            controller: patientSignupVM.cityController,
            fillColor: Colors.white.withOpacity(0.2),
            errorcolor: Colors.red,
            hintText: 'City',
            prefixIcon: const Icon(
              LucideIcons.mapPin,
              color: Colors.white,
            ),
            prefixIconWidth: 80.0,
            validator: (String? value) {
              if (value!.isEmpty) {
                return 'Please enter your city';
              }
              return null;
            },
          ),
          SizedBox(height: height * .02),
          Row(
            children: [
              Text(
                'Gender',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Obx(() => Row(
                children: [
                  Radio<String>(
                    value: 'male',
                    groupValue: patientSignupVM.gender.value,
                    onChanged: (value) => patientSignupVM.gender.value = value!,
                    fillColor: MaterialStateProperty.all(Colors.white),
                  ),
                  Text(
                    'Male',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Radio<String>(
                    value: 'female',
                    groupValue: patientSignupVM.gender.value,
                    onChanged: (value) => patientSignupVM.gender.value = value!,
                    fillColor: MaterialStateProperty.all(Colors.white),
                  ),
                  Text(
                    'Female',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ],
              )),
            ],
          ),
          SizedBox(height: height * .03),
          Center(
            child: Obx(() => RoundButton(
              title: 'SIGN UP',
              width: double.infinity,
              buttonColor: AppColors.darkGreen,
              textColor: Colors.white,
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
                  patientSignupVM.signUpPatient(); // Example function
                }
              },
              loading: patientSignupVM.loading.value,
            )),
          ),
          SizedBox(height: height * .03),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have a Patient Account? ",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(RouteName.loginPage), // Assuming you have a general login page
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}