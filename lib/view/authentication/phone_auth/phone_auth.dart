import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sehatyab/res/routes/routes_name.dart';
import 'package:sehatyab/view_model/controller/authentication_controller/phone_no_auth_controller.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/input_field.dart';
import '../../../res/components/round_button.dart';
import '../../../res/device_size/device_size.dart';

class PhoneAuthenticationPage extends StatelessWidget {
  final _authVM = Get.put(PhoneAuthViewModel());

  PhoneAuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: _buildResponsiveLayout(context),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isWeb ? _webLayout() : _mobileLayout(),
      ),
    );
  }

  Widget _webLayout() {
    return Container(
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
      child: _authForm(),
    );
  }

  Widget _mobileLayout() {
    return _authForm();
  }

  Widget _authForm() {
    return Form(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Phone Authentication',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: height * 0.1),
          InputField(
            controller: _authVM.phoneNumberController,
            hintText: '03XXXXXXXX',
            fillColor: Colors.lightBlue,
            prefixIcon: const Icon(Icons.phone, color: Colors.white),
            validator: (value) => _validatePhoneNumber(value),
          ),
          SizedBox(height: height * 0.05),
          Obx(() => RoundButton(
            title: "Send OTP",
            loading: _authVM.loading.value,
            onPress: _authVM.sendOtp,
            buttonColor: AppColors.darkGreen,
            textColor: Colors.white,
          )),
          SizedBox(height: height * 0.05),
          _loginRedirect(),
        ],
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Enter phone number';
    if (!RegExp(r'^03\d{8}$').hasMatch(value)) {
      return 'Invalid format (e.g. 03001234567)';
    }
    return null;
  }

  Widget _loginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        GestureDetector(
          onTap: () => Get.toNamed(RouteName.loginPage),
          child: Text(
            'Login',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),

      ],
    );
  }
}