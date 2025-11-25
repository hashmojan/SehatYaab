import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor/review/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a review and update average
  Future<void> submitReview(Review review) async {
    try {
      print('Submitting review for doctor: ${review.doctorEmail}');

      final doctorReviewDocRef = _firestore
          .collection('doctor_reviews')
          .doc(review.doctorEmail);

      // First, add the review to subcollection
      await doctorReviewDocRef
          .collection('reviews')
          .doc(review.id)
          .set(review.toMap());

      print('Review added to subcollection, updating summary...');

      // Then update the review summary
      await _updateReviewSummary(review.doctorEmail);

      print('Review submitted successfully!');
    } catch (e) {
      print('Error submitting review: $e');
      throw Exception('Failed to submit review: $e');
    }
  }

  // Update an existing review
  Future<void> updateReview(Review review) async {
    try {
      print('Updating review: ${review.id}');

      await _firestore
          .collection('doctor_reviews')
          .doc(review.doctorEmail)
          .collection('reviews')
          .doc(review.id)
          .update({
        'rating': review.rating,
        'comment': review.comment,
      });

      print('Review updated, updating summary...');

      // Update the summary after modification
      await _updateReviewSummary(review.doctorEmail);

      print('Review update completed successfully!');
    } catch (e) {
      print('Error updating review: $e');
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String doctorEmail, String reviewId) async {
    try {
      print('Deleting review: $reviewId');

      await _firestore
          .collection('doctor_reviews')
          .doc(doctorEmail)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      print('Review deleted, updating summary...');

      // Update the summary after deletion
      await _updateReviewSummary(doctorEmail);

      print('Review deletion completed successfully!');
    } catch (e) {
      print('Error deleting review: $e');
      throw Exception('Failed to delete review: $e');
    }
  }

  // Update review summary by calculating from all reviews
  Future<void> _updateReviewSummary(String doctorEmail) async {
    try {
      print('Updating review summary for: $doctorEmail');

      final reviewsSnapshot = await _firestore
          .collection('doctor_reviews')
          .doc(doctorEmail)
          .collection('reviews')
          .get();

      print('Found ${reviewsSnapshot.docs.length} reviews');

      if (reviewsSnapshot.docs.isEmpty) {
        // If no reviews, delete the summary document
        await _firestore
            .collection('doctor_reviews')
            .doc(doctorEmail)
            .delete();
        print('No reviews found, deleted summary document');
        return;
      }

      double totalRating = 0;
      int totalReviews = reviewsSnapshot.docs.length;
      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in reviewsSnapshot.docs) {
        try {
          final data = doc.data();
          print('Processing review data: $data');

          // Safe rating extraction
          dynamic ratingData = data['rating'];
          double rating = 0.0;

          if (ratingData is int) {
            rating = ratingData.toDouble();
          } else if (ratingData is double) {
            rating = ratingData;
          } else if (ratingData is String) {
            rating = double.tryParse(ratingData) ?? 0.0;
          }

          totalRating += rating;

          final ratingInt = rating.round().clamp(1, 5);
          ratingDistribution[ratingInt] = (ratingDistribution[ratingInt] ?? 0) + 1;

          print('Processed rating: $rating, rounded to: $ratingInt');
        } catch (e) {
          print('Error processing review ${doc.id}: $e');
          continue; // Skip problematic reviews
        }
      }

      final averageRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;

      print('Calculated average: $averageRating, total reviews: $totalReviews');
      print('Rating distribution: $ratingDistribution');

      final summary = DoctorReviewSummary(
        doctorEmail: doctorEmail,
        averageRating: averageRating,
        totalReviews: totalReviews,
        ratingDistribution: ratingDistribution,
      );

      // Store summary in the doctor_reviews document
      await _firestore
          .collection('doctor_reviews')
          .doc(doctorEmail)
          .set(summary.toMap());

      print('Review summary updated successfully!');
    } catch (e) {
      print('Error updating review summary: $e');
      throw Exception('Failed to update review summary: $e');
    }
  }

  // Get review summary for a doctor
  Stream<DoctorReviewSummary?> getReviewSummary(String doctorEmail) {
    return _firestore
        .collection('doctor_reviews')
        .doc(doctorEmail)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        print('No review summary found for: $doctorEmail');
        return null;
      }

      try {
        final data = snapshot.data()!;
        print('Retrieved review summary data: $data');
        return DoctorReviewSummary.fromMap(data);
      } catch (e) {
        print('Error parsing review summary: $e');
        return null;
      }
    });
  }

  // Get all reviews for a doctor
  Stream<List<Review>> getReviewsForDoctor(String doctorEmail) {
    return _firestore
        .collection('doctor_reviews')
        .doc(doctorEmail)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Review.fromMap(doc.id, doc.data());
        } catch (e) {
          print('Error parsing review ${doc.id}: $e');
          // Return a default review in case of error
          return Review(
            id: doc.id,
            patientId: 'unknown',
            patientName: 'Unknown',
            doctorEmail: doctorEmail,
            rating: 0.0,
            comment: 'Error loading review',
            createdAt: DateTime.now(),
          );
        }
      }).toList();
    });
  }

  // Check if patient has already reviewed this doctor
  Future<bool> hasPatientReviewed(String doctorEmail, String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('doctor_reviews')
          .doc(doctorEmail)
          .collection('reviews')
          .where('patientId', isEqualTo: patientId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if patient reviewed: $e');
      return false;
    }
  }

  // Get a specific review by patient and doctor
  Future<Review?> getPatientReview(String doctorEmail, String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('doctor_reviews')
          .doc(doctorEmail)
          .collection('reviews')
          .where('patientId', isEqualTo: patientId)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Review.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
    } catch (e) {
      print('Error getting patient review: $e');
      return null;
    }
  }
}