import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/doctor/doctor_model/doctor_review.dart';

class ReviewService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _doctorCol() =>
      _db.collection('doctors');

  /// Stream all reviews for a doctor (newest first)
  Stream<List<DoctorReview>> streamDoctorReviews(String doctorId) {
    return _doctorCol()
        .doc(doctorId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DoctorReview.fromDoc(d)).toList());
  }

  /// Get a specific patient's review doc for a doctor (1 review per patient)
  Future<DoctorReview?> getMyReview({
    required String doctorId,
    required String patientId,
  }) async {
    final doc = await _doctorCol()
        .doc(doctorId)
        .collection('reviews')
        .doc(patientId)
        .get();
    if (!doc.exists) return null;
    return DoctorReview.fromDoc(doc);
  }

  /// Add or update a review (and atomically update doctor.ratingAvg / ratingCount)
  Future<void> addOrUpdateReview({
    required String doctorId,
    required String patientId,
    required String patientName,
    required int rating, // 1..5
    String? comment,
    String? appointmentId,
  }) async {
    final doctorRef = _doctorCol().doc(doctorId);
    final reviewRef = doctorRef.collection('reviews').doc(patientId);

    await _db.runTransaction((tx) async {
      final doctorSnap = await tx.get(doctorRef);
      final hasDoctor = doctorSnap.exists;

      if (!hasDoctor) {
        throw StateError('Doctor not found');
      }

      final currentAvg = ((doctorSnap.data()?['ratingAvg']) ?? 0.0) as num;
      final currentCount = ((doctorSnap.data()?['ratingCount']) ?? 0) as num;

      final now = DateTime.now();
      final newReviewData = {
        'doctorId': doctorId,
        'patientId': patientId,
        'patientName': patientName,
        'rating': rating,
        'comment': comment,
        'appointmentId': appointmentId,
        'updatedAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      };

      final existing = await tx.get(reviewRef);
      num nextAvg = currentAvg.toDouble();
      num nextCount = currentCount.toInt();

      if (existing.exists) {
        // If updating an existing review, adjust average without changing count.
        final oldRating = ((existing.data()?['rating']) ?? 0) as num;
        if (nextCount == 0) {
          nextAvg = rating.toDouble();
          nextCount = 1;
        } else {
          nextAvg = ((currentAvg * currentCount) - oldRating + rating) / nextCount;
        }

        tx.set(
          reviewRef,
          {
            ...newReviewData,
            'createdAt': existing.data()!['createdAt'] as Timestamp,
          },
          SetOptions(merge: true),
        );
      } else {
        // New review: increase count and recompute average.
        final newCount = (currentCount.toInt()) + 1;
        final sum = (currentAvg * currentCount) + rating;
        nextAvg = sum / newCount;
        nextCount = newCount;

        tx.set(reviewRef, newReviewData);
      }

      // Keep just two decimals for UI consistency
      final clampedAvg = double.parse(nextAvg.toStringAsFixed(2));

      tx.update(doctorRef, {
        'ratingAvg': clampedAvg,
        'ratingCount': nextCount,
      });
    });
  }
}
