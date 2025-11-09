import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../models/doctor/doctor_model/doctor_review.dart';
import '../../../services/doctor_review/review_services.dart';

class DoctorReviewsController extends GetxController {
  DoctorReviewsController({required this.doctorId});

  final String doctorId;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _service = ReviewService();

  // State
  final reviews = <DoctorReview>[].obs;
  final ratingAvg = 0.0.obs;
  final ratingCount = 0.obs;

  final isPatient = false.obs;
  final hasMyReview = false.obs;
  final myRating = RxnInt();
  final myComment = RxnString();

  // UI helpers
  final isSubmitting = false.obs;

  StreamSubscription? _doctorSub;
  StreamSubscription? _reviewsSub;

  String? get uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _bindDoctorHeader();
    _bindReviews();
    _detectRoleAndMyReview();
  }

  void _bindDoctorHeader() {
    _doctorSub = _db.collection('doctors').doc(doctorId).snapshots().listen((d) {
      final data = d.data();
      ratingAvg.value = ((data?['ratingAvg']) ?? 0.0 as num).toDouble();
      ratingCount.value = ((data?['ratingCount']) ?? 0 as num).toInt();
    });
  }

  void _bindReviews() {
    _reviewsSub = _service.streamDoctorReviews(doctorId).listen((list) {
      reviews.assignAll(list);
    });
  }

  Future<void> _detectRoleAndMyReview() async {
    final u = uid;
    if (u == null) {
      isPatient.value = false;
      hasMyReview.value = false;
      return;
    }
    // users/{uid}.userType == 'patient'
    final userDoc =
    await _db.collection('users').doc(u).get(const GetOptions(source: Source.serverAndCache));
    final type = userDoc.data()?['userType'];
    isPatient.value = type == 'patient';

    if (isPatient.value) {
      final my = await _service.getMyReview(doctorId: doctorId, patientId: u);
      if (my != null) {
        hasMyReview.value = true;
        myRating.value = my.rating;
        myComment.value = my.comment;
      } else {
        hasMyReview.value = false;
        myRating.value = null;
        myComment.value = null;
      }
    }
  }

  Future<void> submit({required int rating, String? comment, String? appointmentId}) async {
    final u = uid;
    if (u == null) return;
    isSubmitting.value = true;
    try {
      // patient name from patients/{uid} (fallback to displayName)
      final pDoc = await _db.collection('patients').doc(u).get();
      final patientName = (pDoc.data()?['name'] as String?) ??
          (_auth.currentUser?.displayName ?? 'Patient');

      await _service.addOrUpdateReview(
        doctorId: doctorId,
        patientId: u,
        patientName: patientName,
        rating: rating,
        comment: comment,
        appointmentId: appointmentId,
      );
      hasMyReview.value = true;
      myRating.value = rating;
      myComment.value = comment;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    _doctorSub?.cancel();
    _reviewsSub?.cancel();
    super.onClose();
  }
}
