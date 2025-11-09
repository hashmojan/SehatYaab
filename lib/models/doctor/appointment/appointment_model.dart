import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final String? doctorImage;
  final String? patientImage;
  final String doctorSpecialty;
  final Timestamp date;   // normalized (00:00)
  final String dateKey;   // yyyy-MM-dd
  final String timeSlot;  // label
  final String slotKey;   // "0900-1000"
  final String status;    // pending/confirmed/cancelled/rejected/completed
  final String? notes;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    required this.doctorSpecialty,
    required this.date,
    required this.dateKey,
    required this.timeSlot,
    required this.slotKey,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.doctorImage,
    this.patientImage,
  });

  factory Appointment.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Appointment(
      id: doc.id,
      doctorId: (d['doctorId'] ?? '') as String,
      patientId: (d['patientId'] ?? '') as String,
      doctorName: (d['doctorName'] ?? '') as String,
      patientName: (d['patientName'] ?? '') as String,
      doctorSpecialty: (d['doctorSpecialty'] ?? '') as String,
      date: (d['date'] as Timestamp?) ?? Timestamp.now(),
      dateKey: (d['dateKey'] ?? '') as String,
      timeSlot: (d['timeSlot'] ?? '') as String,
      slotKey: (d['slotKey'] ?? '') as String,
      status: (d['status'] ?? 'pending') as String,
      createdAt: (d['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: (d['updatedAt'] as Timestamp?) ?? Timestamp.now(),
      notes: d['notes'] as String?,
      doctorImage: d['doctorImage'] as String?,
      patientImage: d['patientImage'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'doctorId': doctorId,
    'patientId': patientId,
    'doctorName': doctorName,
    'patientName': patientName,
    'doctorSpecialty': doctorSpecialty,
    'date': date,
    'dateKey': dateKey,
    'timeSlot': timeSlot,
    'slotKey': slotKey,
    'status': status,
    'notes': notes,
    'doctorImage': doctorImage,
    'patientImage': patientImage,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
