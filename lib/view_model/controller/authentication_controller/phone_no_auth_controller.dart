import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../../res/routes/routes_name.dart';
import '../../../utils/utils.dart';
import '../../../utils/firebase_firestor_services.dart';

class PhoneAuthViewModel extends GetxController {
  final phoneNumberController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();

  final loading = false.obs;
  final isOtpSent = false.obs;
  final verificationId = Rxn<String>();
  final resendToken = Rxn<int>();
  final countdown = 60.obs;
  final canResend = false.obs;
  final _storedPhone = ''.obs;
  final _storedPassword = ''.obs;

  final FirestoreService _firestoreService = FirestoreService();
  Timer? _resendTimer;

  @override
  void onClose() {
    phoneNumberController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    _resendTimer?.cancel();
    super.onClose();
  }

  void _startResendCountdown() {
    canResend.value = false;
    countdown.value = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  Future<void> sendOtp() async {
    // Store credentials
    _storedPhone.value = phoneNumberController.text.trim();
    _storedPassword.value = passwordController.text;

    // Validate passwords
    if (_storedPassword.value != confirmPasswordController.text) {
      Utils.showSnackBar('Error', 'Passwords do not match');
      return;
    }

    if (_storedPassword.value.length < 6) {
      Utils.showSnackBar('Error', 'Password must be at least 6 characters');
      return;
    }

    // Validate phone number
    if (_storedPhone.value.isEmpty || !_isValidPakistaniNumber(_storedPhone.value)) {
      Utils.showSnackBar('Error', 'Invalid Pakistani number (e.g. 03001234567)');
      return;
    }

    final formattedNumber = _formatNumber(_storedPhone.value);
    loading.value = true;
    isOtpSent.value = false;
    otpController.clear();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: _handleVerificationComplete,
        verificationFailed: _handleVerificationFailed,
        codeSent: _handleCodeSent,
        codeAutoRetrievalTimeout: (vId) => verificationId.value = vId,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken.value,
      );

      Get.toNamed(RouteName.otpPage);
    } catch (e) {
      loading.value = false;
      Utils.showSnackBar('Error', 'Failed to send OTP: ${e.toString()}');
    }
  }

  bool _isValidPakistaniNumber(String number) {
    return RegExp(r'^03\d{9}$').hasMatch(number);
  }

  String _formatNumber(String localNumber) {
    return '+92${localNumber.substring(1)}';
  }

  Future<void> _handleVerificationComplete(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _createUserDocument(userCredential.user!);
      _navigateAfterVerification();
    } catch (e) {
      loading.value = false;
      Utils.showSnackBar('Error', 'Auto-verification failed: ${e.toString()}');
    }
  }

  void _handleVerificationFailed(FirebaseAuthException e) {
    loading.value = false;
    Utils.showSnackBar('Error', _parseError(e));
  }

  void _handleCodeSent(String vId, int? token) {
    if (vId.isEmpty) return;

    verificationId.value = vId;
    resendToken.value = token;
    isOtpSent.value = true;
    loading.value = false;
    _startResendCountdown();
    Utils.showSnackBar('OTP Sent', '6-digit code sent to your number');
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.length != 6 || verificationId.value == null) {
      Utils.showSnackBar('Error', 'Enter valid 6-digit OTP');
      return;
    }

    loading.value = true;

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value!,
        smsCode: otp,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _createUserDocument(userCredential.user!);
      _navigateAfterVerification();
    } on FirebaseAuthException catch (e) {
      Utils.showSnackBar('Error', _parseError(e));
    } catch (e) {
      Utils.showSnackBar('Error', 'OTP verification failed: ${e.toString()}');
    } finally {
      loading.value = false;
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      // await _firestoreService.createPatient(
      //   uid: user.uid,
      //   phoneNumber: _storedPhone.value,
      //   password: _storedPassword.value,
      // );

      // Create email/password account for future logins
      await user.updateEmail(_generateEmail(_storedPhone.value));
      await user.updatePassword(_storedPassword.value);
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  String _generateEmail(String phone) => '$phone@sehatyab.patient';

  String _parseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number': return 'Invalid phone number format';
      case 'too-many-requests': return 'Too many attempts. Try later';
      case 'quota-exceeded': return 'SMS quota exceeded';
      case 'session-expired': return 'OTP expired. Resend new code';
      case 'invalid-verification-code': return 'Invalid OTP entered';
      default: return e.message ?? 'Authentication failed';
    }
  }

  void _navigateAfterVerification() {
    loading.value = false;
    Get.offAllNamed(RouteName.homePage);
  }
}