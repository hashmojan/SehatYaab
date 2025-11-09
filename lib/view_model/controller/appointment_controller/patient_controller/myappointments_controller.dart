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

  /// LISTEN FROM PATIENT SUBCOLLECTION (no composite index needed)
  void _fetchAppointments() {
    final uid = currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    _appointmentsSubscription = _firestore
        .collection('patients')
        .doc(uid)
        .collection('appointments')
        .orderBy('createdAt', descending: true) // single-field index only
        .snapshots()
        .listen((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // ensure we always have an id field
        return {
          'id': data['id'] ?? doc.id,
          ...data,
        };
      }).toList();

      appointments.assignAll(items);
      isLoading.value = false;
    }, onError: (error) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to load appointments: $error');
      debugPrint('Error fetching appointments: $error');
    });
  }

  /// CANCEL across all mirrors + update daily availability at new path
  Future<void> cancelAppointment(String appointmentId, String doctorId) async {
    isCancelling.value = true;
    try {
      final uid = currentUserId;
      if (uid == null) throw Exception('Not signed in');

      // Read the patient copy first (authoritative for patient UI)
      final patientApptRef = _firestore
          .collection('patients')
          .doc(uid)
          .collection('appointments')
          .doc(appointmentId);

      final patientSnap = await patientApptRef.get();
      if (!patientSnap.exists) {
        throw Exception('Appointment not found.');
      }
      final appt = patientSnap.data() as Map<String, dynamic>;
      final DateTime date =
      appt['date'] is Timestamp ? (appt['date'] as Timestamp).toDate() : DateTime.now();
      final String dateKey =
          appt['dateKey'] ?? DateFormat('yyyy-MM-dd').format(date);

      // Refs to all mirrors (update if exist; create if you prefer)
      final topRef = _firestore.collection('appointments').doc(appointmentId);
      final doctorApptRef = _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('appointments')
          .doc(appointmentId);

      // New daily availability path (no composite index needed)
      final dailyRef = _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('daily_availability')
          .doc(dateKey);

      await _firestore.runTransaction((tx) async {
        // decrement daily availability (if exists, and count > 0)
        final dailySnap = await tx.get(dailyRef);
        if (dailySnap.exists) {
          final map = dailySnap.data() as Map<String, dynamic>;
          final int currentCount = (map['appointmentsCount'] as num?)?.toInt() ?? 0;
          tx.update(dailyRef, {
            'appointmentsCount': currentCount > 0 ? currentCount - 1 : 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // update patient copy
        tx.update(patientApptRef, {
          'status': 'cancelled',
          'cancellationReason': 'Cancelled by patient',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // update doctor copy (if it exists)
        final dSnap = await tx.get(doctorApptRef);
        if (dSnap.exists) {
          tx.update(doctorApptRef, {
            'status': 'cancelled',
            'cancellationReason': 'Cancelled by patient',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // update top-level mirror (if it exists)
        final tSnap = await tx.get(topRef);
        if (tSnap.exists) {
          tx.update(topRef, {
            'status': 'cancelled',
            'cancellationReason': 'Cancelled by patient',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      Get.snackbar(
        'Success',
        'Appointment cancelled successfully.',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.canvasColor,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel appointment: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('Error cancelling appointment: $e');
    } finally {
      isCancelling.value = false;
    }
  }
}
