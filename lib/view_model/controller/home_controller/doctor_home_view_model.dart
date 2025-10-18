// view_model/controller/home_controller/doctor_home_view_model.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../../../models/doctor/appointment/appointment_model.dart';
import '../../../services/notification_services/notification_services.dart';

class DoctorHomeViewModel extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive state
  final RxBool isLoading = true.obs;
  final RxList<Appointment> pendingAppointments = <Appointment>[].obs;
  final RxList<Appointment> upcomingAppointments = <Appointment>[].obs;
  final RxList<Appointment> historyAppointments = <Appointment>[].obs;

  late String doctorId;
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;

  @override
  void onInit() {
    super.onInit();
    final user = _auth.currentUser;
    if (user != null) {
      doctorId = user.uid;
      _subscribeToAppointments();
    } else {
      Get.snackbar('Error', 'User not authenticated.');
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _appointmentsSubscription?.cancel();
    super.onClose();
  }

  void _subscribeToAppointments() {
    isLoading.value = true;
    _appointmentsSubscription = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      // Clear all lists before repopulating
      pendingAppointments.clear();
      upcomingAppointments.clear();
      historyAppointments.clear();

      for (var doc in snapshot.docs) {
        final appointment = Appointment.fromFirestore(doc);
        if (appointment.status == 'pending') {
          pendingAppointments.add(appointment);
        } else if (appointment.status == 'confirmed') {
          upcomingAppointments.add(appointment);
        } else {
          historyAppointments.add(appointment);
        }
      }
      isLoading.value = false;
    }, onError: (e) {
      Get.snackbar('Error', 'Failed to fetch appointments: $e');
      isLoading.value = false;
      debugPrint("Error fetching appointments: $e");
    });
  }

  Future<void> confirmAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Success', 'Appointment confirmed.');
      _sendAppointmentNotification(appointmentId, 'confirmed');
    } catch (e) {
      Get.snackbar('Error', 'Failed to confirm appointment: $e');
      debugPrint('Error confirming appointment: $e');
    }
  }

  Future<void> completeAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Success', 'Appointment marked as completed.');
      _sendAppointmentNotification(appointmentId, 'completed');
    } catch (e) {
      Get.snackbar('Error', 'Failed to complete appointment: $e');
      debugPrint('Error completing appointment: $e');
    }
  }

  Future<void> rejectAppointment(String appointmentId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final appointmentRef = _firestore.collection('appointments').doc(appointmentId);
        final appointmentSnapshot = await transaction.get(appointmentRef);

        if (!appointmentSnapshot.exists) {
          throw Exception("Appointment not found.");
        }

        final appointmentData = appointmentSnapshot.data();
        if (appointmentData == null) {
          throw Exception("Appointment data is null.");
        }

        // 1. Get the date to find the correct daily availability document
        final Timestamp dateTimestamp = appointmentData['date'];
        final String formattedDate = DateFormat('yyyy-MM-dd').format(dateTimestamp.toDate());
        final String dailyAvailabilityId = '${doctorId}_$formattedDate';
        final dailyAvailabilityRef = _firestore.collection('daily_availability').doc(dailyAvailabilityId);

        // 2. Decrement the appointmentsCount using a transaction
        final dailyAvailabilitySnapshot = await transaction.get(dailyAvailabilityRef);
        if (dailyAvailabilitySnapshot.exists) {
          transaction.update(dailyAvailabilityRef, {
            'appointmentsCount': FieldValue.increment(-1),
          });
        }

        // 3. Update the appointment status
        transaction.update(appointmentRef, {
          'status': 'rejected', // Use 'rejected' status
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      Get.snackbar('Success', 'Appointment rejected successfully.');
      _sendAppointmentNotification(appointmentId, 'rejected');
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject appointment: $e');
      debugPrint('Error rejecting appointment: $e');
    }
  }

  Future<void> _sendAppointmentNotification(String appointmentId, String status) async {
    try {
      final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final appointment = Appointment.fromFirestore(appointmentDoc);

      await NotificationService.sendAppointmentNotification(
        userId: appointment.patientId,
        title: 'Appointment ${status.capitalizeFirst}',
        body: 'Your appointment with Dr. ${appointment.doctorName} has been ${status}.',
        data: {
          'type': 'appointment_${status}',
          'appointmentId': appointmentId,
        },
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  Future<void> addPrescriptionAndNotes(String appointmentId, String notes, String prescription) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'notes': notes,
        'prescription': prescription,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Get.snackbar('Success', 'Notes and prescription added successfully.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add notes and prescription: $e');
      debugPrint('Error adding notes and prescription: $e');
    }
  }

  String get formattedToday => DateFormat('EEEE, MMMM d').format(DateTime.now());
}