import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorReview {
  final String id; // review doc id = patientId (1 review per patient per doctor)
  final String doctorId;
  final String patientId;
  final String patientName;
  final int rating; // 1..5
  final String? comment;
  final String? appointmentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorReview({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.rating,
    this.comment,
    this.appointmentId,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(rating >= 1 && rating <= 5, 'rating must be in 1..5');

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'rating': rating,
      'comment': comment,
      'appointmentId': appointmentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DoctorReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DoctorReview(
      id: doc.id,
      doctorId: data['doctorId'] as String,
      patientId: data['patientId'] as String,
      patientName: (data['patientName'] ?? '') as String,
      rating: (data['rating'] as num).toInt(),
      comment: data['comment'] as String?,
      appointmentId: data['appointmentId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
