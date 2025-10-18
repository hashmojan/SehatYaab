// view_model/controller/appointment_controller/doctor_controller/doctor_availability_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../models/doctor/appointment/availability_model.dart';
import '../../../../services/notification_services/notification_services.dart';

class DoctorDailyAvailabilityController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxString _doctorId = ''.obs;
  final RxMap<String, DailyAvailabilityModel> dailyAvailability = RxMap();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final focusedDay = DateTime.now().obs;
  final selectedDay = Rx<DateTime?>(null);
  final RxSet<DateTime> selectedDays = <DateTime>{}.obs;

  StreamSubscription<QuerySnapshot>? _availabilitySubscription;

  String get doctorId => _doctorId.value;

  @override
  void onInit() {
    super.onInit();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _doctorId.value = user.uid;
      _listenForDailyAvailability();
    } else {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _availabilitySubscription?.cancel();
    super.onClose();
  }

  void _listenForDailyAvailability() {
    if (_doctorId.value.isEmpty) return;

    _availabilitySubscription = _firestore
        .collection('daily_availability')
        .where('doctorId', isEqualTo: _doctorId.value)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .where('date', isLessThan: Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))))
        .snapshots()
        .listen((snapshot) {
      final updatedData = <String, DailyAvailabilityModel>{};
      for (var doc in snapshot.docs) {
        final dailyData = DailyAvailabilityModel.fromMap(doc.data(), doc.id);
        final dateKey = DateFormat('yyyy-MM-dd').format(dailyData.date);
        updatedData[dateKey] = dailyData;

        // Update selected days for UI
        if (dailyData.status == 'available') {
          selectedDays.add(DateTime(dailyData.date.year, dailyData.date.month, dailyData.date.day));
        }
      }
      dailyAvailability.value = updatedData;
      isLoading.value = false;
    }, onError: (error) {
      Get.snackbar('Error', 'Failed to load daily availability: $error');
      isLoading.value = false;
    });
  }

  void setSelectedDay(DateTime day) {
    selectedDay.value = day;
  }

  void setFocusedDay(DateTime day) {
    focusedDay.value = day;
  }

  void toggleSelectedDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    if (selectedDays.contains(normalizedDay)) {
      selectedDays.remove(normalizedDay);
    } else {
      selectedDays.add(normalizedDay);
    }
    selectedDay.value = normalizedDay;
  }

  Future<void> setAvailableDays(List<DateTime> dates) async {
    isSaving.value = true;

    try {
      final batch = _firestore.batch();
      final normalizedDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();

      // Set selected dates to available
      for (var date in normalizedDates) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final docId = '${_doctorId.value}_$dateKey';
        final docRef = _firestore.collection('daily_availability').doc(docId);

        // Get current appointments count if exists
        final docSnapshot = await docRef.get();
        final currentAppointmentsCount = docSnapshot.exists ?
        (docSnapshot.data()?['appointmentsCount'] ?? 0) : 0;

        batch.set(docRef, {
          'doctorId': _doctorId.value,
          'date': Timestamp.fromDate(date),
          'status': 'available',
          'patientLimit': 20,
          'appointmentsCount': currentAppointmentsCount,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Set non-selected dates to unavailable
      final allAvailabilitySnapshot = await _firestore
          .collection('daily_availability')
          .where('doctorId', isEqualTo: _doctorId.value)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .get();

      for (var doc in allAvailabilitySnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final normalizedDate = DateTime(date.year, date.month, date.day);

        if (!normalizedDates.contains(normalizedDate) && data['status'] == 'available') {
          batch.update(doc.reference, {
            'status': 'unavailable',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      Get.snackbar('Success', 'Availability updated successfully for ${dates.length} days.');

    } catch (e) {
      Get.snackbar('Error', 'Failed to update availability: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateDailyAvailability({
    required DateTime date,
    required String status,
    required int patientLimit,
  }) async {
    isSaving.value = true;

    try {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dateKey = DateFormat('yyyy-MM-dd').format(normalizedDate);
      final docId = '${_doctorId.value}_$dateKey';
      final docRef = _firestore.collection('daily_availability').doc(docId);

      final doc = await docRef.get();
      final int currentAppointmentsCount = doc.exists ?
      (doc.data()?['appointmentsCount'] ?? 0) : 0;

      // Update selected days set
      if (status == 'available') {
        selectedDays.add(normalizedDate);
      } else {
        selectedDays.remove(normalizedDate);
      }

      await docRef.set({
        'doctorId': _doctorId.value,
        'date': Timestamp.fromDate(normalizedDate),
        'status': status,
        'patientLimit': status == 'available' ? patientLimit : 0,
        'appointmentsCount': status == 'available' ? currentAppointmentsCount : 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': doc.exists ? doc.data()!['createdAt'] : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.snackbar('Success', 'Availability for $dateKey updated successfully');

      if (status == 'unavailable') {
        await _checkForConflicts(normalizedDate);
      }

    } catch (e) {
      Get.snackbar('Error', 'Failed to update availability: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _checkForConflicts(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    try {
      final appointments = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: _doctorId.value)
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('date', isEqualTo: dateKey)
          .get();

      if (appointments.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();

        for (final doc in appointments.docs) {
          final appointment = doc.data();
          batch.update(doc.reference, {
            'status': 'cancelled',
            'cancellationReason': 'Doctor availability changed',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Send notification
          NotificationService.sendAppointmentNotification(
            userId: appointment['patientId'],
            title: 'Appointment Cancelled',
            body: 'Your appointment with Dr. ${appointment['doctorName'] ?? 'N/A'} on $dateKey has been cancelled due to a schedule change.',
            data: {
              'type': 'appointment_cancelled',
              'appointmentId': doc.id,
              'doctorName': appointment['doctorName'] ?? 'N/A',
            },
          );
        }

        await batch.commit();
        Get.snackbar('Info', 'Cancelled ${appointments.docs.length} appointments for $dateKey.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to check for conflicts: $e');
    }
  }

  bool isDayAvailable(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final dailyData = dailyAvailability[dateKey];
    return dailyData?.status == 'available' && (dailyData?.isFull() == false);
  }

  bool isDayFull(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final dailyData = dailyAvailability[dateKey];
    if (dailyData != null) {
      return dailyData.isFull();
    }
    return false;
  }

  int getAvailableSlots(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final dailyData = dailyAvailability[dateKey];
    if (dailyData?.status == 'available') {
      return dailyData!.patientLimit - dailyData.appointmentsCount;
    }
    return 0;
  }

  // Method to increment appointment count when a new appointment is booked
  Future<void> incrementAppointmentCount(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey = DateFormat('yyyy-MM-dd').format(normalizedDate);
    final docId = '${_doctorId.value}_$dateKey';
    final docRef = _firestore.collection('daily_availability').doc(docId);

    try {
      await docRef.update({
        'appointmentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to update appointment count: $e');
    }
  }

  // Method to decrement appointment count when an appointment is cancelled
  Future<void> decrementAppointmentCount(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final dateKey = DateFormat('yyyy-MM-dd').format(normalizedDate);
    final docId = '${_doctorId.value}_$dateKey';
    final docRef = _firestore.collection('daily_availability').doc(docId);

    try {
      await docRef.update({
        'appointmentsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to update appointment count: $e');
    }
  }
}