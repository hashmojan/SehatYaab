import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/round_button.dart';
import '../../../res/routes/routes_name.dart';
import '../../../utils/utils.dart';

class OTPPage extends StatefulWidget {
  const OTPPage({super.key});

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 60;
  String _verificationId = '';
  String _phoneNumber = '';
  int? _resendToken;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initializeArguments();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _initializeArguments() {
    final args = Get.arguments;

    if (args == null) {
      Utils.showSnackBar('Error', 'Session expired. Please try again.');
      Get.offAllNamed(RouteName.otpPage);
      return;
    }

    setState(() {
      _verificationId = args['verificationId'] ?? '';
      _phoneNumber = args['phoneNumber'] ?? '';
      _resendToken = args['resendToken'];
    });

    if (_verificationId.isEmpty) {
      Utils.showSnackBar('Error', 'Invalid verification data');
      Get.offAllNamed(RouteName.otpPage);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      Utils.showSnackBar("Error", "Please enter a valid 6-digit OTP");
      return;
    }

    if (_verificationId.isEmpty) {
      Utils.showSnackBar("Error", "Session expired. Please request new OTP.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      debugPrint("Attempting to sign in with verificationId: $_verificationId");

      final authResult = await FirebaseAuth.instance.signInWithCredential(credential);

      if (authResult.user == null) {
        throw Exception("User authentication failed");
      }

      debugPrint("User UID: ${authResult.user?.uid}");
      Get.offAllNamed(RouteName.patientHomePage);

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Authentication failed";
      if (e.code == 'invalid-verification-code') {
        errorMessage = "Invalid OTP entered";
      } else if (e.code == 'session-expired') {
        errorMessage = "OTP expired. Please request a new one";
      }
      Utils.showSnackBar("Error", "$errorMessage (${e.code})");
    } catch (e) {
      Utils.showSnackBar("Error", "Authentication failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending || _phoneNumber.isEmpty) return;

    setState(() => _isResending = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneNumber,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          Utils.showSnackBar("Error", "Failed to resend OTP: ${e.message}");
          if (mounted) {
            setState(() => _isResending = false);
          }
        },
        codeSent: (String newVerificationId, int? newResendToken) {
          if (mounted) {
            setState(() {
              _verificationId = newVerificationId;
              _resendToken = newResendToken;
              _countdown = 60;
              _isResending = false;
            });
          }
          _startCountdown();
          Utils.showSnackBar("Success", "New OTP sent successfully");
        },
        codeAutoRetrievalTimeout: (_) {},
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      Utils.showSnackBar("Error", "Failed to resend OTP: ${e.toString()}");
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: isWeb
                ? Container(
              width: 400,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: _buildFormContent(),
            )
                : _buildFormContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Verify OTP',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Sent to $_phoneNumber',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.password, color: Colors.white),
            hintText: 'Enter 6-digit OTP',
            hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
            fillColor: Colors.white.withOpacity(0.2),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            counterText: '',
          ),
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        const SizedBox(height: 20),
        _countdown > 0
            ? Text(
          'Resend OTP in $_countdown seconds',
          style: GoogleFonts.poppins(color: Colors.white70),
        )
            : TextButton(
          onPressed: _isResending ? null : _resendOtp,
          child: _isResending
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            'Resend OTP',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
        const SizedBox(height: 30),
        _isLoading
            ? CircularProgressIndicator(color: AppColors.secondaryColor)
            : RoundButton(
          onPress: _verifyOtp,
          title: "Verify OTP",
          buttonColor: AppColors.darkGreen,
          textColor: Colors.white,
        ),
      ],
    );
  }
}