import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../res/routes/routes_name.dart';
import '../../../utils/firebase_firestor_services.dart';
import '../../../utils/utils.dart';

class DoctorSignupViewModel extends GetxController {
  // Change these to regular TextEditingController and use .obs for the whole controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final specializationController = TextEditingController();
  final titleController = TextEditingController();
  final yearsOfExperienceController = TextEditingController(); // NEW


  final gender = 'male'.obs;

  final loading = false.obs;

  Future<void> signUpDoctor() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        cityController.text.isEmpty ||
        specializationController.text.isEmpty ||
        titleController.text.isEmpty ||
        yearsOfExperienceController.text.isEmpty || // NEW


        gender.value.isEmpty) {
      Utils.showSnackBar('Error', "Please fill in all the required fields.");
      return;
    }

    loading.value = true;

    try {
      final _firestoreService = FirestoreService();
      final auth = FirebaseAuth.instance;

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) { // Safer null check
        await _firestoreService.createDoctor(
          uid: userCredential.user!.uid,
          email: emailController.text.trim(),
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          city: cityController.text.trim(),
          specialization: specializationController.text.trim(),
          title: titleController.text.trim(),
          yearsOfExperience: yearsOfExperienceController.text.trim(), // NEW

          gender: gender.value,
        );

        loading.value = false;
        Get.offAllNamed(RouteName.doctorHomePage);
      } else {
        loading.value = false;
        Utils.showSnackBar('Error', 'Failed to create user account.');
        print('User creation failed - userCredential.user is null');
      }
    } on FirebaseAuthException catch (ex) {
      loading.value = false;
      Utils.showSnackBar('Firebase Error', ex.message ?? ex.code.toString());
    } catch (error) {
      loading.value = false;
      Utils.showSnackBar('Error', error.toString());
      print('Signup error: $error');
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    specializationController.dispose();
    yearsOfExperienceController.dispose(); // NEW

    titleController.dispose();
    super.onClose();
  }
}