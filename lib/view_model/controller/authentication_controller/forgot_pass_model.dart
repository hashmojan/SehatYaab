import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../utils/utils.dart';

class ForgotPassModel extends GetxController {
  final emailController = TextEditingController().obs;

  // final emailFocusNode=FocusNode().obs;
  // final passwordFocusNode=FocusNode().obs;
  RxBool loading = false.obs;

  forgotPassword() {
    if (emailController.value.toString().isEmpty) {
      Utils.showSnackBar("Enter Email to Reset", "Please fill in all the required fields.");
    }
    try{
      // loading.value = true;
        FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.value.text.trim());
        Utils.showSnackBar("Success", "Password reset email has been sent.");
        loading.value = false;
    } on FirebaseAuthException catch (ex) {
      loading.value = false;
      Utils.showSnackBar('Firebase Catch', ex.code.toString());
    } finally {
      loading.value = false;
    }

  }

}
