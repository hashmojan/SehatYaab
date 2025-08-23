import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/input_field.dart';
import '../../../res/components/round_button.dart';
import '../../../res/device_size/device_size.dart';
import '../../../res/routes/routes_name.dart';
import '../../../view_model/controller/authentication_controller/forgot_pass_model.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with SingleTickerProviderStateMixin {
  final _formkey = GlobalKey<FormState>();
  late AnimationController _animationController;

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
                height: height * 0.9,
                width: 400, // Set the width for the container on web
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
                child: _buildFormContent(context),
              )
                  : _buildFormContent(context), // Full-screen layout for mobile
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    final ForgotPassVM = Get.put(ForgotPassModel());
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
            child: Text(
              'Reset Password',
              style: GoogleFonts.poppins(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: height * .02),
          InputField(
            controller: ForgotPassVM.emailController.value,
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
          TextButton(
            onPressed: () {
              Get.toNamed(RouteName.loginPage);
            },
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Back to Login Screen',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          SizedBox(height: height * .01),
          Center(
            child: Obx(() => RoundButton(
              buttonColor: AppColors.darkGreen,
              onPress: () {
                if (_formkey.currentState!.validate()) {
                  ForgotPassVM.loading.value = true; // Update loading before API call
                  ForgotPassVM.forgotPassword();
                }
              },
              title: "Reset Password",
              loading: ForgotPassVM.loading.value,
              textColor: Colors.white,
            )),
          ),
        ],
      ),
    );
  }
}