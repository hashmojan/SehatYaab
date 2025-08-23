import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../res/routes/routes_name.dart';

class LoginViewModel extends GetxController {
  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;
  final phoneController = TextEditingController().obs;

  final loading = false.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<bool> loginWithPhoneAndPassword({
    required String phone,
    required String password
  }) async {
    try {
      loading.value = true;
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _generatePatientEmail(phone),
        password: password,
      );

      await _verifyUserType(userCredential.user?.uid, 'patient');
      return true;
    } catch (e) {
      return false;
    } finally {
      loading.value = false;
    }
  }

  String _generatePatientEmail(String phone) => "$phone@patients.sehatyab";

  Future<bool> login({required String userType}) async {
    if (emailController.value.text.isEmpty || passwordController.value.text.isEmpty) {
      return false;
    }

    loading.value = true;
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.value.text.trim(),
        password: passwordController.value.text.trim(),
      );

      await _verifyUserType(userCredential.user?.uid, userType);
      return true;
    } catch (e) {
      return false;
    } finally {
      loading.value = false;
    }
  }

  Future<void> signInWithGoogle({required bool isPatient}) async {
    try {
      loading.value = true;
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception("Google sign in cancelled");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      final userDoc = await _firestore.collection('users').doc(userCredential.user?.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'email': userCredential.user?.email,
          'name': userCredential.user?.displayName,
          'userType': isPatient ? 'patient' : 'doctor',
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': userCredential.user?.photoURL,
        });
      } else {
        final userData = userDoc.data() as Map<String, dynamic>;
        final dbUserType = userData['userType']?.toString().toLowerCase();
        final expectedType = isPatient ? 'patient' : 'doctor';

        if (dbUserType != expectedType) {
          await _auth.signOut();
          await _googleSignIn.signOut();
          throw Exception("Please login as a ${userData['userType']}");
        }
      }

      Get.offAllNamed(isPatient ? RouteName.patientHomePage : RouteName.doctorHomePage);
    } catch (e) {
      rethrow;
    } finally {
      loading.value = false;
    }
  }

  Future<void> _verifyUserType(String? userId, String expectedType) async {
    if (userId == null) throw Exception("User ID not found");
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) throw Exception("User document not found");

    final userData = userDoc.data() as Map<String, dynamic>;
    final dbUserType = userData['userType']?.toString().toLowerCase();

    if (dbUserType != expectedType.toLowerCase()) {
      await _auth.signOut();
      throw Exception("Please login as a ${userData['userType']}");
    }
  }

  @override
  void onClose() {
    emailController.value.dispose();
    passwordController.value.dispose();
    phoneController.value.dispose();
    super.onClose();
  }
}