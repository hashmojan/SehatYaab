// lib/view_model/controller/home_controller/doctor_home_view_model.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/doctor/appointment/appointment_model.dart';

class DoctorHomeViewModel extends GetxController {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final isLoading = true.obs;

  final RxList<Appointment> pendingAppointments = <Appointment>[].obs;
  final RxList<Appointment> upcomingAppointments = <Appointment>[].obs;
  final RxList<Appointment> historyAppointments = <Appointment>[].obs;

  String get formattedToday => DateFormat.yMMMMd().format(DateTime.now());

  Stream<List<Appointment>>? _subStream;
  Stream<List<Appointment>>? _fallbackTopStream;
  StreamSubscription? _subListener;
  StreamSubscription? _topListener;

  @override
  void onInit() {
    super.onInit();
    _subscribe();
  }

  @override
  void onClose() {
    _subListener?.cancel();
    _topListener?.cancel();
    super.onClose();
  }

  void _subscribe() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    _subStream = _db
        .collection('doctors')
        .doc(uid)
        .collection('appointments')
        .orderBy('createdAt', descending: false) // single-field index
        .snapshots()
        .map((snap) => snap.docs.map((d) => Appointment.fromDoc(d)).toList());

    _subListener = _subStream!.listen((list) {
      _partition(list);
      isLoading.value = false;

      // If the subcollection is empty (older data might live only in top-level),
      // start a one-time live fallback to the top-level to avoid blank screens.
      if (list.isEmpty) {
        _listenTopLevelOnce(uid);
      } else {
        _topListener?.cancel();
      }
    }, onError: (_) {
      isLoading.value = false;
    });
  }

  void _listenTopLevelOnce(String uid) {
    _topListener?.cancel();
    _fallbackTopStream = _db
        .collection('appointments')
        .where('doctorId', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Appointment.fromDoc(d)).toList());

    _topListener = _fallbackTopStream!.listen((list) {
      // Only use as a fallback if doctor subcollection is empty
      if (pendingAppointments.isEmpty &&
          upcomingAppointments.isEmpty &&
          historyAppointments.isEmpty) {
        _partition(list);
      }
      isLoading.value = false;
    }, onError: (_) {
      isLoading.value = false;
    });
  }

  void _partition(List<Appointment> all) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    pendingAppointments.value =
        all.where((a) => a.status == 'pending').toList();

    upcomingAppointments.value = all.where((a) {
      final isFutureOrToday =
      (a.dateKey ?? '').isNotEmpty ? (a.dateKey!.compareTo(todayKey) >= 0) : true;
      return a.status == 'confirmed' && isFutureOrToday;
    }).toList();

    historyAppointments.value = all.where((a) {
      final ended = ['cancelled', 'rejected', 'completed'].contains(a.status);
      if (ended) return true;
      // push past confirmed into history if its day is gone
      final isPast =
      (a.dateKey ?? '').isNotEmpty ? (a.dateKey!.compareTo(todayKey) < 0) : false;
      return a.status == 'confirmed' && isPast;
    }).toList();
  }

  // ---------- Helpers to write to all mirrors safely ----------

  Future<void> _safeUpdate(Map<String, dynamic> patch, {
    required DocumentReference ref,
  }) async {
    final snap = await ref.get();
    if (snap.exists) {
      await ref.update(patch);
    }
  }

  Future<void> _updateStatusEverywhere(Appointment a, String status, {String? reason}) async {
    final patch = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (reason != null) 'cancellationReason': reason,
    };

    final docRef = _db
        .collection('doctors')
        .doc(a.doctorId)
        .collection('appointments')
        .doc(a.id);

    final patientRef = _db
        .collection('patients')
        .doc(a.patientId)
        .collection('appointments')
        .doc(a.id);

    // top-level mirror (optional)
    final topRef = _db.collection('appointments').doc(a.id);

    await Future.wait([
      _safeUpdate(patch, ref: docRef),
      _safeUpdate(patch, ref: patientRef),
      _safeUpdate(patch, ref: topRef),
    ]);
  }

  Future<void> _decrementDailyIfNeeded(Appointment a) async {
    final statusesToCount = {'pending', 'confirmed'};
    if (!statusesToCount.contains(a.status)) return;

    final dayRef = _db
        .collection('doctors')
        .doc(a.doctorId)
        .collection('daily_availability')
        .doc(a.dateKey);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(dayRef);
      if (!snap.exists) return;
      final map = snap.data() as Map<String, dynamic>;
      final current = (map['appointmentsCount'] as num?)?.toInt() ?? 0;
      tx.update(dayRef, {
        'appointmentsCount': current > 0 ? current - 1 : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }


  Future<void> confirmAppointment(Appointment a) async {
    // move from pending -> confirmed
    await _updateStatusEverywhere(a, 'confirmed');
  }

  Future<void> rejectAppointment(Appointment a) async {
    // free the slot and mark as rejected everywhere
    await _decrementDailyIfNeeded(a);
    await _updateStatusEverywhere(a, 'rejected', reason: 'Rejected by doctor');
  }

  Future<void> cancelAppointment(Appointment a) async {
    // doctor-initiated cancellation (similar to reject)
    await _decrementDailyIfNeeded(a);
    await _updateStatusEverywhere(a, 'cancelled', reason: 'Cancelled by doctor');
  }

  Future<void> completeAppointment(Appointment a) async {
    await _updateStatusEverywhere(a, 'completed');
  }
}
