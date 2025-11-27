import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/doctor/appointment/appointment_model.dart';

class DoctorHomeViewModel extends GetxController {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Set to false initially, refreshData will set it to true when loading starts
  final isLoading = false.obs;

  final RxList<Appointment> pendingAppointments = <Appointment>[].obs;
  final RxList<Appointment> upcomingAppointments = <Appointment>[].obs;
  final RxList<Appointment> historyAppointments = <Appointment>[].obs;

  String get formattedToday => DateFormat.yMMMMd().format(DateTime.now());

  StreamSubscription? _subListener;
  StreamSubscription? _topListener;

  @override
  void onInit() {
    super.onInit();
    // Initialize with empty data to avoid null issues
    _safeClearLists();
  }

  // Use onReady to ensure the view is ready before the initial data fetch
  @override
  void onReady() {
    super.onReady();
    // Use delayed initialization to avoid build conflicts
    Future.microtask(() {
      refreshData();
    });
  }

  @override
  void onClose() {
    _cancelListeners();
    super.onClose();
  }

  /// Safely clear lists using microtask to avoid build phase conflicts
  void _safeClearLists() {
    Future.microtask(() {
      pendingAppointments.clear();
      upcomingAppointments.clear();
      historyAppointments.clear();
    });
  }

  /// Cancels all active Firestore stream listeners.
  void _cancelListeners() {
    _subListener?.cancel();
    _topListener?.cancel();
    _subListener = null;
    _topListener = null;
    // Clear data lists when listeners are cancelled (e.g., on logout)
    _safeClearLists();
  }

  /// Refreshes the appointment data based on the currently logged-in doctor.
  Future<void> refreshData() async {
    final uid = _auth.currentUser?.uid;

    // Clear old data and listeners first
    _cancelListeners();

    if (uid == null) {
      // Use microtask to avoid setState during build
      Future.microtask(() {
        isLoading.value = false;
      });
      return;
    }

    // Use microtask to avoid setState during build
    Future.microtask(() {
      isLoading.value = true;
    });

    _subscribe(uid); // Start subscription with the current UID
  }

  void _subscribe(String uid) {
    final subStream = _db
        .collection('doctors')
        .doc(uid)
        .collection('appointments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Appointment.fromDoc(d)).toList());

    _subListener = subStream.listen((list) {
      _partition(list);
      // Use microtask to avoid setState during build
      Future.microtask(() {
        isLoading.value = false;
      });

      // Fallback logic
      if (list.isEmpty) {
        _listenTopLevelOnce(uid);
      } else {
        _topListener?.cancel();
        _topListener = null;
      }
    }, onError: (_) {
      // Use microtask to avoid setState during build
      Future.microtask(() {
        isLoading.value = false;
      });
    });
  }

  void _listenTopLevelOnce(String uid) {
    _topListener?.cancel();

    final fallbackTopStream = _db
        .collection('appointments')
        .where('doctorId', isEqualTo: uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Appointment.fromDoc(d)).toList());

    _topListener = fallbackTopStream.listen((list) {
      // Only use as a fallback if the doctor subcollection is truly empty
      if (pendingAppointments.isEmpty &&
          upcomingAppointments.isEmpty &&
          historyAppointments.isEmpty) {
        _partition(list);
      }
      // Use microtask to avoid setState during build
      Future.microtask(() {
        isLoading.value = false;
      });
    }, onError: (_) {
      // Use microtask to avoid setState during build
      Future.microtask(() {
        isLoading.value = false;
      });
    });
  }

  void _partition(List<Appointment> all) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Use microtask to update observables safely
    Future.microtask(() {
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
    });
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
    await _updateStatusEverywhere(a, 'confirmed');
  }

  Future<void> rejectAppointment(Appointment a) async {
    await _decrementDailyIfNeeded(a);
    await _updateStatusEverywhere(a, 'rejected', reason: 'Rejected by doctor');
  }

  Future<void> cancelAppointment(Appointment a) async {
    await _decrementDailyIfNeeded(a);
    await _updateStatusEverywhere(a, 'cancelled', reason: 'Cancelled by doctor');
  }

  Future<void> completeAppointment(Appointment a) async {
    await _updateStatusEverywhere(a, 'completed');
  }
}