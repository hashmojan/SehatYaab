class Review {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorEmail;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorEmail': doctorEmail,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static Review fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      doctorEmail: map['doctorEmail']?.toString() ?? '',
      rating: (map['rating'] is int)
          ? (map['rating'] as int).toDouble()
          : (map['rating'] as double? ?? 0.0),
      comment: map['comment']?.toString() ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] is int)
            ? map['createdAt'] as int
            : (map['createdAt'] as double?)?.toInt() ?? 0,
      ),
    );
  }
}

class DoctorReviewSummary {
  final String doctorEmail;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  DoctorReviewSummary({
    required this.doctorEmail,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  Map<String, dynamic> toMap() {
    // Convert Map<int, int> to Map<String, int> for Firestore
    Map<String, int> stringKeyDistribution = {};
    ratingDistribution.forEach((key, value) {
      stringKeyDistribution[key.toString()] = value;
    });

    return {
      'doctorEmail': doctorEmail,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': stringKeyDistribution, // Use string keys for Firestore
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static DoctorReviewSummary fromMap(Map<String, dynamic> map) {
    Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    if (map['ratingDistribution'] != null) {
      final distribution = map['ratingDistribution'];

      if (distribution is Map<String, dynamic>) {
        // Handle string keys (from Firestore)
        distribution.forEach((key, value) {
          final intKey = int.tryParse(key) ?? 0;
          final intValue = _safeIntConvert(value);
          if (intKey >= 1 && intKey <= 5) {
            ratingDistribution[intKey] = intValue;
          }
        });
      } else if (distribution is Map<int, dynamic>) {
        // Handle int keys (if they come as integers)
        distribution.forEach((key, value) {
          final intValue = _safeIntConvert(value);
          if (key >= 1 && key <= 5) {
            ratingDistribution[key] = intValue;
          }
        });
      }
    }

    return DoctorReviewSummary(
      doctorEmail: map['doctorEmail']?.toString() ?? '',
      averageRating: (map['averageRating'] is int)
          ? (map['averageRating'] as int).toDouble()
          : (map['averageRating'] as double? ?? 0.0),
      totalReviews: _safeIntConvert(map['totalReviews']),
      ratingDistribution: ratingDistribution,
    );
  }

  static int _safeIntConvert(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}