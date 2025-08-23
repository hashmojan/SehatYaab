// doctor_schedule_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../models/doctor/schedule_slot/schedule_slot.dart';
import '../../../../services/auth_services/auth_services.dart';

class DoctorScheduleProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<ScheduleSlot> _scheduleSlots = [];
  DateTime _currentWeekStart = DateTime.now();

  // For weekly view
  final List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  bool get isLoading => _isLoading;
  List<ScheduleSlot> get scheduleSlots => _scheduleSlots;
  DateTime get currentWeekStart => _currentWeekStart;
  DateTime get currentWeekEnd => _currentWeekStart.add(const Duration(days: 6));

  DoctorScheduleProvider() {
    _adjustWeekStart();
    fetchSchedule();
  }

  void _adjustWeekStart() {
    _currentWeekStart = _currentWeekStart.subtract(
        Duration(days: _currentWeekStart.weekday - 1)
    );
    notifyListeners();
  }

  // Navigation for weekly view
  void previousWeek() {
    _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    fetchSchedule();
  }

  void nextWeek() {
    _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    fetchSchedule();
  }

  Future<void> fetchSchedule() async {
    try {
      _isLoading = true;
      notifyListeners();

      final weekEnd = currentWeekEnd;

      final querySnapshot = await _firestore
          .collection('doctor_schedules')
          .where('doctorId', isEqualTo: AuthService().currentUserId)
          .where('date', isGreaterThanOrEqualTo: _currentWeekStart)
          .where('date', isLessThanOrEqualTo: weekEnd)
          .orderBy('date')
          .get();

      _scheduleSlots = querySnapshot.docs.map((doc) => ScheduleSlot.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Failed to fetch schedule: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ScheduleSlot> getSlotsForDay(String day) {
    return _scheduleSlots.where((slot) => slot.day == day).toList();
  }

  Future<void> addNewSlot({
    required String day,
    required String startTime,
    required String endTime,
    required int maxAppointments,
    required bool isAvailable,
  }) async {
    try {
      final docRef = await _firestore.collection('doctor_schedules').add({
        'doctorId': AuthService().currentUserId,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'date': _getNextDateForDay(day),
        'isAvailable': isAvailable,
        'maxAppointments': maxAppointments,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _scheduleSlots.add(ScheduleSlot(
        id: docRef.id,
        doctorId: AuthService().currentUserId ?? '',        day: day,
        startTime: startTime,
        endTime: endTime,
        date: _getNextDateForDay(day),
        isAvailable: isAvailable,
        maxAppointments: maxAppointments,
      ));
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add schedule: ${e.toString()}');
    }
  }

  Future<void> updateSlot({
    required String id,
    required String day,
    required String startTime,
    required String endTime,
    required int maxAppointments,
    required bool isAvailable,
  }) async {
    try {
      await _firestore.collection('doctor_schedules').doc(id).update({
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'isAvailable': isAvailable,
        'maxAppointments': maxAppointments,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _scheduleSlots.indexWhere((s) => s.id == id);
      if (index != -1) {
        _scheduleSlots[index] = _scheduleSlots[index].copyWith(
          day: day,
          startTime: startTime,
          endTime: endTime,
          isAvailable: isAvailable,
          maxAppointments: maxAppointments,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update schedule: ${e.toString()}');
    }
  }

  Future<void> addWeeklySchedule({
    required List<String> days,
    required String startTime,
    required String endTime,
    required int maxAppointments,
    bool isAvailable = true,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final batch = _firestore.batch();
      final newSlots = <ScheduleSlot>[];

      for (final day in days) {
        final date = _getNextDateForDay(day);
        final docRef = _firestore.collection('doctor_schedules').doc();

        batch.set(docRef, {
          'doctorId': AuthService().currentUserId,
          'day': day,
          'startTime': startTime,
          'endTime': endTime,
          'date': date,
          'isAvailable': isAvailable,
          'maxAppointments': maxAppointments,
          'createdAt': FieldValue.serverTimestamp(),
        });

        newSlots.add(ScheduleSlot(
          id: docRef.id,
          doctorId: AuthService().currentUserId ?? '',
          day: day,
          startTime: startTime,
          endTime: endTime,
          date: date,
          isAvailable: isAvailable,
          maxAppointments: maxAppointments,
        ));
      }

      await batch.commit();
      _scheduleSlots.addAll(newSlots);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to add weekly schedule: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime _getNextDateForDay(String day) {
    final today = DateTime.now();
    final dayIndex = daysOfWeek.indexOf(day);
    var date = today;

    // Find the next occurrence of this day
    while (date.weekday - 1 != dayIndex) {
      date = date.add(const Duration(days: 1));
    }

    return date;
  }

  Future<void> deleteSlot(String slotId) async {
    try {
      await _firestore.collection('doctor_schedules').doc(slotId).delete();
      _scheduleSlots.removeWhere((slot) => slot.id == slotId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete schedule: ${e.toString()}');
    }
  }
}