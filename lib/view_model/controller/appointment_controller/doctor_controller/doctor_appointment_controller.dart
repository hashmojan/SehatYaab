// view_model/controller/appointment_controller/doctor_controller/doctor_appointment_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../services/notification_services/notification_services.dart';

class DoctorAppointmentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive state
  final selectedDate = Rx<DateTime?>(null);
  final selectedSlot = Rx<String?>(null);
  final availableDates = <DateTime>[].obs;
  final availableSlots = <String>[].obs;
  final bookedAppointments = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isUpdating = false.obs;

  // Doctor and user info
  late String doctorId;
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _appointmentsSubscription;

  @override
  void onInit() {
    super.onInit();
    if (_auth.currentUser != null) {
      doctorId = _auth.currentUser!.uid;
      _loadInitialData();
    } else {
      print('Doctor is not logged in.');
      // Optionally, navigate to login or handle unauthenticated state
    }
  }

  @override
  void onClose() {
    _appointmentsSubscription?.cancel();
    super.onClose();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    selectedDate.value = DateTime.now();
    await _loadAvailableDates();
    await _subscribeToAppointments();
    isLoading.value = false;
  }

  Future<void> _loadAvailableDates() async {
    final now = DateTime.now();
    availableDates.assignAll(
        List.generate(30, (index) => now.add(Duration(days: index + 1)))
    );
    if (selectedDate.value != null) {
      await _loadSlotsForDate(selectedDate.value!);
    }
  }

  Future<void> _subscribeToAppointments() async {
    if (doctorId.isEmpty) { // Ensure doctorId is set before querying
      print('Doctor ID is empty, cannot subscribe to appointments.');
      return;
    }
    _appointmentsSubscription = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(Duration(days:1))))
        .orderBy('date')
        .snapshots()
        .listen((snapshot) {
      bookedAppointments.assignAll(
          snapshot.docs.map((doc) => doc.data()).toList()
      );
      if (selectedDate.value != null) {
        _updateAvailableSlots(selectedDate.value!);
      }
    }, onError: (error) {
      print("Error fetching appointments: $error");
      Get.snackbar('Error', 'Failed to load appointments: $error');
    });
  }

  void _updateAvailableSlots(DateTime date) {
    _loadSlotsForDate(date);
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = date;
    selectedSlot.value = null;
    await _loadSlotsForDate(date);
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    isLoading.value = true;
    availableSlots.clear();

    try {
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      final availability = doctorDoc.data()?['availability'] ?? {};

      final allGeneratedSlots = _generateAllSlotsForDate(date, availability);

      final bookedSlots = bookedAppointments
          .where((appt) =>
      (appt['date'] as Timestamp).toDate().day == date.day &&
          (appt['date'] as Timestamp).toDate().month == date.month &&
          (appt['date'] as Timestamp).toDate().year == date.year &&
          (appt['status'] == 'pending' || appt['status'] == 'confirmed'))
          .map((appt) => appt['time'] as String)
          .toSet();

      availableSlots.assignAll(
          allGeneratedSlots.where((slot) => !bookedSlots.contains(slot)).toList()
      );

      if (date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year) {
        final currentTime = DateFormat('HH:mm').format(DateTime.now());
        availableSlots.assignAll(
            availableSlots.where((slot) => slot.compareTo(currentTime) > 0).toList()
        );
      }

    } catch (e) {
      Get.snackbar('Error', 'Failed to load time slots: $e');
      print('Error loading time slots: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<String> _generateAllSlotsForDate(DateTime date, Map<String, dynamic> availability) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final exceptions = availability['exceptions'] as List<dynamic>? ?? [];

    for (final exception in exceptions) {
      if (exception['date'] == dateStr) {
        if (exception['isAvailable'] == true && exception['customSlots'] is List) {
          return (exception['customSlots'] as List).cast<String>();
        } else if (exception['isAvailable'] == false) {
          return [];
        }
      }
    }

    final generalSettings = availability['generalSettings'] as Map<String, dynamic>?;

    if (generalSettings == null) {
      print('General settings not found in doctor availability.');
      return [];
    }

    final workingDays = generalSettings['workingDays'] as List<dynamic>? ?? [];
    if (!workingDays.contains(date.weekday)) {
      return [];
    }

    final workingHours = generalSettings['workingHours'] as Map<String, dynamic>?;
    final breakTime = generalSettings['breakTime'] as Map<String, dynamic>?;
    final appointmentDuration = generalSettings['appointmentDuration'] as int? ?? 30;

    if (workingHours == null || workingHours['start'] == null || workingHours['end'] == null ||
        breakTime == null || breakTime['start'] == null || breakTime['end'] == null) {
      print('Incomplete working hours or break time settings.');
      return [];
    }

    return _generateTimeSlots(
      workingHours['start'] as String,
      workingHours['end'] as String,
      breakTime['start'] as String,
      breakTime['end'] as String,
      appointmentDuration,
    );
  }

  List<String> _generateTimeSlots(String startHour, String endHour, String breakStartHour, String breakEndHour, int durationMinutes) {
    List<String> slots = [];
    final DateFormat timeFormat = DateFormat('HH:mm');

    DateTime startTime = DateTime.parse('2000-01-01 $startHour:00');
    DateTime endTime = DateTime.parse('2000-01-01 $endHour:00');
    DateTime breakStartTime = DateTime.parse('2000-01-01 $breakStartHour:00');
    DateTime breakEndTime = DateTime.parse('2000-01-01 $breakEndHour:00');

    DateTime currentSlot = startTime;
    while (currentSlot.isBefore(endTime)) {
      String formattedSlot = timeFormat.format(currentSlot);

      bool isInBreak = (currentSlot.isAtSameMomentAs(breakStartTime) || currentSlot.isAfter(breakStartTime)) &&
          currentSlot.isBefore(breakEndTime);

      if (!isInBreak) {
        slots.add(formattedSlot);
      }
      currentSlot = currentSlot.add(Duration(minutes: durationMinutes));
    }
    return slots;
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      isUpdating.value = true;

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final appointment = appointmentDoc.data();

      if (appointment != null) {
        await NotificationService.sendAppointmentNotification(
          userId: appointment['patientId'],
          title: 'Appointment ${status.capitalizeFirst}',
          body: 'Your appointment with Dr. ${appointment['doctorName'] ?? 'N/A'} has been ${status}.',
          data: {
            'type': 'appointment_${status}',
            'appointmentId': appointmentId,
            'doctorName': appointment['doctorName'] ?? 'N/A',
          },
        );
      }

      Get.snackbar('Success', 'Appointment status updated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update appointment: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isUpdating.value = false;
    }
  }

  // This method will be used for cancelling, simply calling updateAppointmentStatus
  Future<void> cancelAppointment(String appointmentId) async {
    await updateAppointmentStatus(appointmentId, 'cancelled');
  }

  Future<void> rescheduleAppointment(
      String appointmentId,
      DateTime newDate,
      String newTime,
      ) async {
    try {
      isUpdating.value = true;

      final isAvailable = await _checkSlotAvailability(newDate, newTime, excludeAppointmentId: appointmentId);
      if (!isAvailable) {
        Get.snackbar('Error', 'The selected slot is no longer available or conflicts with another appointment.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return;
      }

      await _firestore.collection('appointments').doc(appointmentId).update({
        'date': Timestamp.fromDate(newDate),
        'time': newTime,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final appointment = appointmentDoc.data();

      if (appointment != null) {
        await NotificationService.sendAppointmentNotification(
          userId: appointment['patientId'],
          title: 'Appointment Rescheduled',
          body: 'Your appointment with Dr. ${appointment['doctorName'] ?? 'N/A'} has been rescheduled to ${DateFormat('MMM d, yyyy').format(newDate)} at $newTime',
          data: {
            'type': 'appointment_rescheduled',
            'appointmentId': appointmentId,
            'doctorName': appointment['doctorName'] ?? 'N/A',
            'newDate': DateFormat('yyyy-MM-dd').format(newDate),
            'newTime': newTime,
          },
        );
      }

      Get.snackbar('Success', 'Appointment rescheduled successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to reschedule appointment: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> _checkSlotAvailability(DateTime date, String time, {String? excludeAppointmentId}) async {
    try {
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      final availability = doctorDoc.data()?['availability'] ?? {};

      if (!_isSlotAvailableInAvailability(date, time, availability)) {
        return false;
      }

      Query query = _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .where('time', isEqualTo: time)
          .where('status', whereIn: ['pending', 'confirmed']);

      if (excludeAppointmentId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeAppointmentId);
      }

      final snapshot = await query.get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking slot availability: $e');
      return false;
    }
  }

  bool _isSlotAvailableInAvailability(DateTime date, String time, Map<String, dynamic> availability) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final exceptions = availability['exceptions'] as List<dynamic>? ?? [];

    for (final exception in exceptions) {
      if (exception['date'] == dateStr) {
        if (exception['isAvailable'] == true && exception['customSlots'] is List) {
          final List<String> customSlots = (exception['customSlots'] as List).cast<String>();
          return customSlots.contains(time);
        } else if (exception['isAvailable'] == false) {
          return false;
        }
      }
    }

    final generalSettings = availability['generalSettings'] as Map<String, dynamic>?;

    if (generalSettings == null) {
      print('General settings not found in doctor availability during slot check.');
      return false;
    }

    final workingDays = generalSettings['workingDays'] as List<dynamic>? ?? [];
    if (!workingDays.contains(date.weekday)) {
      return false;
    }

    final workingHours = generalSettings['workingHours'] as Map<String, dynamic>?;
    final breakTime = generalSettings['breakTime'] as Map<String, dynamic>?;

    if (workingHours == null || workingHours['start'] == null || workingHours['end'] == null ||
        breakTime == null || breakTime['start'] == null || breakTime['end'] == null) {
      print('Incomplete working hours or break time settings during slot check.');
      return false;
    }

    final String start = workingHours['start'] as String;
    final String end = workingHours['end'] as String;
    final String breakStart = breakTime['start'] as String;
    final String breakEnd = breakTime['end'] as String;

    final isWithinWorkingHours = time.compareTo(start) >= 0 && time.compareTo(end) < 0;
    final isWithinBreakTime = time.compareTo(breakStart) >= 0 && time.compareTo(breakEnd) < 0;

    return isWithinWorkingHours && !isWithinBreakTime;
  }
}