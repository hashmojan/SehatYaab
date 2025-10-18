import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MyAppointmentsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final appointments = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isCancelling = false.obs;

  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _fetchAppointments();
  }

  @override
  void onClose() {
    _appointmentsSubscription?.cancel();
    super.onClose();
  }

  void _fetchAppointments() {
    if (currentUserId == null) {
      isLoading.value = false;
      return;
    }

    _appointmentsSubscription = _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      appointments.assignAll(
          snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()
      );
      isLoading.value = false;
    }, onError: (error) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to load appointments: $error');
      debugPrint('Error fetching appointments: $error');
    });
  }

  Future<void> cancelAppointment(String appointmentId, String doctorId) async {
    isCancelling.value = true;
    try {
      final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
      final appointmentDoc = await appointmentRef.get();
      if (!appointmentDoc.exists) {
        throw Exception('Appointment not found.');
      }
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;

      // Get the date from the appointment data to find the correct daily_availability document
      final date = (appointmentData['date'] as Timestamp).toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final dailyAvailabilityId = '${doctorId}_$dateKey';
      final dailyAvailabilityRef = _firestore.collection('daily_availability').doc(dailyAvailabilityId);

      await _firestore.runTransaction((transaction) async {
        // Decrement the appointmentsCount for the doctor's daily availability
        final dailyAvailabilitySnapshot = await transaction.get(dailyAvailabilityRef);
        if (!dailyAvailabilitySnapshot.exists) {
          throw Exception('Daily availability record not found.');
        }

        final currentAppointmentsCount = dailyAvailabilitySnapshot.data()?['appointmentsCount'] ?? 0;
        final newAppointmentsCount = currentAppointmentsCount > 0 ? currentAppointmentsCount - 1 : 0;

        transaction.update(dailyAvailabilityRef, {
          'appointmentsCount': newAppointmentsCount,
        });

        // Update the appointment status
        transaction.update(appointmentRef, {
          'status': 'cancelled',
          'cancellationReason': 'Cancelled by patient',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      Get.snackbar('Success', 'Appointment cancelled successfully.',
          backgroundColor: Get.theme.primaryColor, colorText: Get.theme.canvasColor);
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel appointment: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      debugPrint('Error cancelling appointment: $e');
    } finally {
      isCancelling.value = false;
    }
  }
}