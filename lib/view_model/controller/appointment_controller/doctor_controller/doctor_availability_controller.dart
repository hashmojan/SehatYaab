// controllers/doctor_availability_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../services/notification_services/notification_services.dart';

class DoctorAvailabilityController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxMap<String, dynamic> availability = RxMap();
  final isLoading = true.obs;
  final isSaving = false.obs;
  StreamSubscription<DocumentSnapshot>? _availabilitySubscription;

  @override
  void onInit() {
    super.onInit();
    _loadAvailability();
  }

  @override
  void onClose() {
    _availabilitySubscription?.cancel();
    super.onClose();
  }

  Future<void> _loadAvailability() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      _availabilitySubscription = _firestore
          .collection('doctors')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          // Ensure 'availability' field exists, otherwise use default
          availability.value = Map<String, dynamic>.from(snapshot.data()!['availability'] ?? _defaultAvailability());
          isLoading.value = false;
        } else {
          // If no availability data exists, set default and save it
          availability.value = _defaultAvailability();
          _firestore.collection('doctors').doc(userId).set(
            {'availability': availability.value},
            SetOptions(merge: true),
          );
          isLoading.value = false;
        }
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load availability: $e');
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _defaultAvailability() {
    return {
      'generalSettings': {
        'workingDays': [1, 2, 3, 4, 5], // Monday to Friday
        'workingHours': {
          'start': '09:00',
          'end': '17:00'
        },
        'breakTime': {
          'start': '12:00',
          'end': '13:00'
        },
        'appointmentDuration': 30, // minutes
      },
      'exceptions': [],
    };
  }

  Future<void> saveAvailability() async {
    try {
      isSaving.value = true;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('doctors').doc(userId).update({
        'availability': availability.value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Check for conflicts
      await _checkForConflicts();

      Get.snackbar('Success', 'Availability updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save availability: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _checkForConflicts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final appointments = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    for (final doc in appointments.docs) {
      final appointment = doc.data();
      final appointmentDate = (appointment['date'] as Timestamp).toDate();
      final appointmentTime = appointment['time'] as String;

      if (!_isSlotAvailable(appointmentDate, appointmentTime)) {
        await _handleConflict(doc.id, appointment);
      }
    }
  }

  bool _isSlotAvailable(DateTime date, String time) {
    // Check if date is in exceptions
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final exceptions = availability['exceptions'] as List<dynamic>? ?? [];

    for (final exception in exceptions) {
      if (exception['date'] == dateStr) {
        // Ensure customSlots is a List<String>
        final List<String> customSlots = (exception['customSlots'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
            [];
        return exception['isAvailable'] == true && customSlots.contains(time);
      }
    }

    // Check general availability
    final workingDays = availability['generalSettings']['workingDays'] as List<dynamic>? ?? [];
    if (!workingDays.contains(date.weekday)) return false;

    final workingHours = availability['generalSettings']['workingHours'];
    final breakTime = availability['generalSettings']['breakTime'];

    // Ensure workingHours and breakTime are not null and contain 'start' and 'end'
    if (workingHours == null ||
        breakTime == null ||
        workingHours['start'] == null ||
        workingHours['end'] == null ||
        breakTime['start'] == null ||
        breakTime['end'] == null) {
      // Handle the case where the data structure is incomplete
      print('Warning: Incomplete availability settings for time check.');
      return false;
    }

    return _isTimeInRange(time, workingHours['start'], workingHours['end']) &&
        !_isTimeInRange(time, breakTime['start'], breakTime['end']);
  }

  bool _isTimeInRange(String time, String start, String end) {
    // Simple time comparison (implement proper time parsing if needed)
    // This assumes time strings are in 'HH:mm' format and can be compared directly
    return time.compareTo(start) >= 0 && time.compareTo(end) < 0; // Use < 0 for end time exclusivity
  }

  Future<void> _handleConflict(String appointmentId, Map<String, dynamic> appointment) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancellationReason': 'Doctor availability changed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify patient
      await NotificationService.sendAppointmentNotification(
        userId: appointment['patientId'],
        title: 'Appointment Cancelled',
        body: 'Your appointment with Dr. ${appointment['doctorName'] ?? 'N/A'} has been cancelled due to schedule changes',
        data: {
          'type': 'appointment_cancelled',
          'appointmentId': appointmentId,
          'doctorName': appointment['doctorName'] ?? 'N/A', // Pass doctor name for context
        },
      );
    } catch (e) {
      print('Error handling conflict: $e');
    }
  }

  // UI Helper Methods
  void updateWorkingDays(List<int> days) {
    // Directly modify the value of the RxMap and then assign it back
    // to trigger reactivity.
    final currentAvailability = Map<String, dynamic>.from(availability.value);
    (currentAvailability['generalSettings'] as Map<String, dynamic>)['workingDays'] = days;
    availability.value = currentAvailability;
  }

  void updateWorkingHours(String start, String end) {
    final currentAvailability = Map<String, dynamic>.from(availability.value);
    (currentAvailability['generalSettings'] as Map<String, dynamic>)['workingHours'] = {'start': start, 'end': end};
    availability.value = currentAvailability;
  }

  void updateBreakTime(String start, String end) {
    final currentAvailability = Map<String, dynamic>.from(availability.value);
    (currentAvailability['generalSettings'] as Map<String, dynamic>)['breakTime'] = {'start': start, 'end': end};
    availability.value = currentAvailability;
  }

  void updateAppointmentDuration(int minutes) {
    final currentAvailability = Map<String, dynamic>.from(availability.value);
    (currentAvailability['generalSettings'] as Map<String, dynamic>)['appointmentDuration'] = minutes;
    availability.value = currentAvailability;
  }

  void addExceptionDate(DateTime date, {bool isAvailable = false, List<String>? customSlots}) {
    final currentAvailability = Map<String, dynamic>.from(availability.value);
    final exceptions = currentAvailability['exceptions'] as List<dynamic>? ?? [];
    exceptions.add({
      'date': DateFormat('yyyy-MM-dd').format(date),
      'isAvailable': isAvailable,
      'customSlots': customSlots ?? [],
    });
    currentAvailability['exceptions'] = exceptions;
    availability.value = currentAvailability;
  }

  void removeExceptionDate(DateTime date) {
    final currentAvailability = Map<String, dynamic>.from(availability.value);
    final exceptions = currentAvailability['exceptions'] as List<dynamic>? ?? [];
    exceptions.removeWhere((e) => e['date'] == DateFormat('yyyy-MM-dd').format(date));
    currentAvailability['exceptions'] = exceptions;
    availability.value = currentAvailability;
  }
}