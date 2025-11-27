import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  // Profile Image
  final profilePic = Rx<File?>(null);
  final profilePicURL = ''.obs;

  // User Information
  final userID = ''.obs;
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userPhone = ''.obs;
  final userSpecialization = ''.obs; // For doctors
  final userHospital = ''.obs;       // For doctors
  final userAge = 0.obs;             // For patients
  final userGender = ''.obs;         // For patients
  final userBloodGroup = ''.obs;     // For patients

  // Account Type
  final userType = Rx<String?>(null); // 'Doctor' or 'Patient'
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      isLoading.value = true;
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        userEmail.value = user.email ?? '';
        userID.value = user.uid;

        // First try to fetch as doctor
        final doctorDoc = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(user.uid)
            .get();

        if (doctorDoc.exists) {
          // User is a doctor
          _populateDoctorData(doctorDoc);
        } else {
          // If not doctor, try to fetch as patient
          final patientDoc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(user.uid)
              .get();

          if (patientDoc.exists) {
            // User is a patient
            _populatePatientData(patientDoc);
          } else {
            // User exists in auth but not in either collection
            Get.snackbar('Error', 'User profile not found');
          }
        }
      }
    } catch (e) {
      // print("Error fetching user data: $e");
      // Get.snackbar('Error', 'Failed to fetch profile data');
    } finally {
      isLoading.value = false;
    }
  }

  void _populateDoctorData(DocumentSnapshot doc) {
    userType.value = 'Doctor';
    userName.value = doc['name'] ?? '';
    profilePicURL.value = doc['profilePicURL'] ?? '';
    userSpecialization.value = doc['specialization'] ?? '';
    userHospital.value = doc['hospital'] ?? '';
    userPhone.value = doc['phone'] ?? '';
  }

  void _populatePatientData(DocumentSnapshot doc) {
    userType.value = 'Patient';
    userName.value = doc['name'] ?? '';
    profilePicURL.value = doc['profilePicURL'] ?? '';
    userAge.value = doc['age'] ?? 0;
    userGender.value = doc['gender'] ?? '';
    userBloodGroup.value = doc['bloodGroup'] ?? '';
    userPhone.value = doc['phone'] ?? '';
  }

  Future<void> uploadImage(File image) async {
    try {
      isLoading.value = true;
      final email = userEmail.value;
      if (email.isEmpty) throw Exception("Email not available");

      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${userID.value}.jpg');

      UploadTask uploadTask = storageReference.putFile(image);
      await uploadTask.whenComplete(() => null);
      String downloadURL = await storageReference.getDownloadURL();

      // Update in the appropriate collection based on user type
      if (userType.value == 'Doctor') {
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(userID.value)
            .update({'profilePicURL': downloadURL});
      } else {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(userID.value)
            .update({'profilePicURL': downloadURL});
      }

      profilePicURL.value = downloadURL;
      Get.snackbar('Success', 'Profile picture updated');
    } catch (e) {
      print("Error uploading image: $e");
      Get.snackbar('Error', 'Failed to upload image');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        profilePic.value = imageFile;
        await uploadImage(imageFile);
      }
    } catch (e) {
      print("Error picking image: $e");
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  // Update profile information based on user type
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      if (userID.value.isEmpty) throw Exception("User ID not available");

      if (userType.value == 'Doctor') {
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(userID.value)
            .update(data);

        // Update local values if they exist in the data
        if (data.containsKey('name')) userName.value = data['name'];
        if (data.containsKey('specialization')) userSpecialization.value = data['specialization'];
        if (data.containsKey('hospital')) userHospital.value = data['hospital'];
        if (data.containsKey('phone')) userPhone.value = data['phone'];
      } else {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(userID.value)
            .update(data);

        // Update local values if they exist in the data
        if (data.containsKey('name')) userName.value = data['name'];
        if (data.containsKey('age')) userAge.value = data['age'];
        if (data.containsKey('gender')) userGender.value = data['gender'];
        if (data.containsKey('bloodGroup')) userBloodGroup.value = data['bloodGroup'];
        if (data.containsKey('phone')) userPhone.value = data['phone'];
      }

      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      print("Error updating profile: $e");
      Get.snackbar('Error', 'Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }

  // Clear profile data on logout
  void clearProfile() {
    profilePic.value = null;
    profilePicURL.value = '';
    userID.value = '';
    userName.value = '';
    userEmail.value = '';
    userPhone.value = '';
    userSpecialization.value = '';
    userHospital.value = '';
    userAge.value = 0;
    userGender.value = '';
    userBloodGroup.value = '';
    userType.value = null;
  }
}