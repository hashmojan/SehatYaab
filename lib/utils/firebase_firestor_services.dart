import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createDoctor({
    required String uid,
    required String email,
    required String name,
    required String phone,
    required String city,
    required String specialization,
    required String title,
    required String gender,
    required String yearsOfExperience,

  }) async {
    try {
      await _firestore.collection('doctors').doc(uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'city': city,
        'specialization': specialization,
        'title': title,
        'gender': gender,
        'yearsOfExperience' : yearsOfExperience ,
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
      });

      // Also create a basic user document
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'userType': 'doctor',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating doctor: $e');
      throw Exception('Failed to create doctor profile');
    }
  }

  Future<void> createPatient({
    required String uid,
    required String email,
    required String name,
    required String phone,
    required String city,
    required String gender,


  }) async {
    try {
      await _firestore.collection('patients').doc(uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'city': city,

        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
        'medicalHistory': {},
      });

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'userType': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating patient: $e');
      throw Exception('Patient creation failed');
    }
  }
}