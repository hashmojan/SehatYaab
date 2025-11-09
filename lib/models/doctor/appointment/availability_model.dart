import 'package:cloud_firestore/cloud_firestore.dart';

class DailyAvailabilityModel {
  final String id;
  final String doctorId;
  final DateTime date;     // normalized to 00:00
  final String dateKey;    // yyyy-MM-dd
  final String status;     // available | unavailable
  final int patientLimit;  // if timeSlots is null, this is used for capacity
  final int appointmentsCount;
  final List<String>? timeSlots; // optional per-day customized slots
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  DailyAvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.dateKey,
    required this.status,
    required this.patientLimit,
    required this.appointmentsCount,
    this.timeSlots,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyAvailabilityModel.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['date'] as Timestamp?;
    final d = ts?.toDate() ?? DateTime.now();
    return DailyAvailabilityModel(
      id: id,
      doctorId: (map['doctorId'] ?? '') as String,
      date: DateTime(d.year, d.month, d.day),
      dateKey: (map['dateKey'] ?? '') as String,
      status: (map['status'] ?? 'unavailable') as String,
      patientLimit: (map['patientLimit'] ?? 0) as int,
      appointmentsCount: (map['appointmentsCount'] ?? 0) as int,
      timeSlots: map['timeSlots'] == null
          ? null
          : List<String>.from(map['timeSlots'] as List<dynamic>),
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'date': Timestamp.fromDate(date),
      'dateKey': dateKey,
      'status': status,
      'patientLimit': patientLimit,
      'appointmentsCount': appointmentsCount,
      'timeSlots': timeSlots,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// A day is full if:
  /// - timeSlots is provided AND appointmentsCount >= timeSlots.length
  /// - else if patientLimit > 0, appointmentsCount >= patientLimit
  bool isFull() {
    if (timeSlots != null && timeSlots!.isNotEmpty) {
      return appointmentsCount >= timeSlots!.length;
    }
    if (patientLimit > 0) {
      return appointmentsCount >= patientLimit;
    }
    return false;
  }
}
