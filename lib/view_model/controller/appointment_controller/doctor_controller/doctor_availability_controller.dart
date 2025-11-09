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

  static String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

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

  /// Listen from: /doctors/{doctorId}/daily_availability
  /// Only filters on 'date' (same field), no composite index needed.
  void _listenForDailyAvailability() {
    if (_doctorId.value.isEmpty) return;

    final start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final end = start.add(const Duration(days: 365));

    final coll = _firestore
        .collection('doctors')
        .doc(_doctorId.value)
        .collection('daily_availability');

    _availabilitySubscription = coll
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .listen((snapshot) {
      final updated = <String, DailyAvailabilityModel>{};
      final newSelected = <DateTime>{};

      for (var doc in snapshot.docs) {
        final m = DailyAvailabilityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        updated[m.dateKey] = m;
        if (m.status == 'available' && !m.isFull()) {
          newSelected.add(DateTime(m.date.year, m.date.month, m.date.day));
        }
      }

      dailyAvailability.value = updated;
      selectedDays
        ..clear()
        ..addAll(newSelected);
      isLoading.value = false;
    }, onError: (e) {
      Get.snackbar('Availability Error', e.toString());
      isLoading.value = false;
    });
  }

  void setSelectedDay(DateTime day) => selectedDay.value = day;
  void setFocusedDay(DateTime day) => focusedDay.value = day;

  void toggleSelectedDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (selectedDays.contains(d)) {
      selectedDays.remove(d);
    } else {
      selectedDays.add(d);
    }
    selectedDay.value = d;
  }

  /// Bulk set available days for the doctor (keeps existing counts/timeSlots)
  Future<void> setAvailableDays(List<DateTime> dates) async {
    isSaving.value = true;
    try {
      final batch = _firestore.batch();
      final normalized = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();

      final baseColl = _firestore
          .collection('doctors')
          .doc(_doctorId.value)
          .collection('daily_availability');

      // Set these days to available
      for (var d in normalized) {
        final key = _dateKey(d);
        final ref = baseColl.doc(key);

        final snap = await ref.get();
        final dataMap = snap.data();

        final int currentCount =
        snap.exists ? ((dataMap?['appointmentsCount'] as num?)?.toInt() ?? 0) : 0;
        final int existingPatientLimit =
            (dataMap?['patientLimit'] as num?)?.toInt() ?? 20;
        final Timestamp? existingCreatedAt =
        snap.exists ? (dataMap?['createdAt'] as Timestamp?) : null;

        batch.set(
          ref,
          {
            'doctorId': _doctorId.value, // optional, but nice to keep
            'date': Timestamp.fromDate(d),
            'dateKey': key,
            'status': 'available',
            'patientLimit': existingPatientLimit,
            'appointmentsCount': currentCount,
            'timeSlots': dataMap?['timeSlots'],
            'createdAt': existingCreatedAt ?? FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // Mark other future available days as unavailable (within 1y window we listen to)
      final futureSnap = await baseColl
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .get();

      for (var doc in futureSnap.docs) {
        final data = doc.data();
        final ts = (data['date'] as Timestamp).toDate();
        final nd = DateTime(ts.year, ts.month, ts.day);
        if (!normalized.contains(nd) && data['status'] == 'available') {
          batch.update(doc.reference, {
            'status': 'unavailable',
            'updatedAt': FieldValue.serverTimestamp(),
            // keep counts/slots as-is (you may also clear them if you want)
          });
        }
      }

      await batch.commit();
      Get.snackbar('Success', 'Availability updated for ${dates.length} day(s).');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update: $e');
    } finally {
      isSaving.value = false;
    }
  }

  /// Update a single day’s availability (with optional custom timeSlots)
  Future<void> updateDailyAvailability({
    required DateTime date,
    required String status,
    required int patientLimit,
    List<String>? timeSlots,
  }) async {
    isSaving.value = true;
    try {
      final nd = DateTime(date.year, date.month, date.day);
      final key = _dateKey(nd);

      final ref = _firestore
          .collection('doctors')
          .doc(_doctorId.value)
          .collection('daily_availability')
          .doc(key);

      final snap = await ref.get();
      final dataMap = snap.data();

      final int currentCount =
      snap.exists ? ((dataMap?['appointmentsCount'] as num?)?.toInt() ?? 0) : 0;
      final Timestamp? existingCreatedAt =
      snap.exists ? (dataMap?['createdAt'] as Timestamp?) : null;

      // update local UI selection set
      if (status == 'available') {
        selectedDays.add(nd);
      } else {
        selectedDays.remove(nd);
      }

      await ref.set({
        'doctorId': _doctorId.value,
        'date': Timestamp.fromDate(nd),
        'dateKey': key,
        'status': status,
        'patientLimit': status == 'available' ? patientLimit : 0,
        'appointmentsCount': status == 'available' ? currentCount : 0,
        'timeSlots': status == 'available' ? (timeSlots ?? dataMap?['timeSlots']) : null,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': existingCreatedAt ?? FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.snackbar('Success', 'Availability for $key saved.');

      if (status == 'unavailable') {
        await _cancelConflictingAppointments(nd);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  /// Cancel doctor’s appointments for a given day (no composite index)
  /// Query path: /doctors/{doctorId}/appointments where dateKey == yyyy-MM-dd
  Future<void> _cancelConflictingAppointments(DateTime date) async {
    final key = _dateKey(date);
    try {
      final apptColl = _firestore
          .collection('doctors')
          .doc(_doctorId.value)
          .collection('appointments');

      final q = await apptColl
          .where('dateKey', isEqualTo: key) // single equality filter
          .get();

      if (q.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in q.docs) {
        final appt = doc.data();

        // Update doctor subcollection doc
        batch.update(doc.reference, {
          'status': 'cancelled',
          'cancellationReason': 'Doctor availability changed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Also update mirrored top-level appointment (if you keep it)
        final topRef = _firestore.collection('appointments').doc(doc.id);
        batch.update(topRef, {
          'status': 'cancelled',
          'cancellationReason': 'Doctor availability changed',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        NotificationService.sendAppointmentNotification(
          userId: appt['patientId'] as String,
          title: 'Appointment Cancelled',
          body:
          'Your appointment with Dr. ${appt['doctorName'] ?? ''} on $key was cancelled due to a schedule change.',
          data: {
            'type': 'appointment_cancelled',
            'appointmentId': doc.id,
            'doctorName': appt['doctorName'] ?? '',
          },
        );
      }
      await batch.commit();

      Get.snackbar('Info', 'Cancelled ${q.docs.length} appointments for $key.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel conflicts: $e');
    }
  }

  bool isDayAvailable(DateTime date) {
    final key = _dateKey(date);
    final d = dailyAvailability[key];
    return d?.status == 'available' && !(d?.isFull() ?? true);
  }

  int getAvailableSlots(DateTime date) {
    final key = _dateKey(date);
    final d = dailyAvailability[key];
    if (d == null || d.status != 'available') return 0;
    if (d.timeSlots != null && d.timeSlots!.isNotEmpty) {
      return d.timeSlots!.length - d.appointmentsCount;
    }
    return d.patientLimit - d.appointmentsCount;
  }

  Future<void> incrementAppointmentCount(DateTime date) async {
    final key = _dateKey(date);
    final ref = _firestore
        .collection('doctors')
        .doc(_doctorId.value)
        .collection('daily_availability')
        .doc(key);

    await ref.update({
      'appointmentsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> decrementAppointmentCount(DateTime date) async {
    final key = _dateKey(date);
    final ref = _firestore
        .collection('doctors')
        .doc(_doctorId.value)
        .collection('daily_availability')
        .doc(key);

    await ref.update({
      'appointmentsCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
