// lib/models/doctor/appointment/appointment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientName;
  final String doctorName;
  final String status;
  final DateTime date;
  final String time;
  final String? patientImage;
  final String? doctorImage;
  final String? doctorSpecialty;
  final int? patientAge;
  final String? notes;
  final String? location;
  final int? tokenNumber;
  final int? queuePosition;
  final String doctorId;
  final String patientId; // Added patientId for notifications

  Appointment({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.status,
    required this.date,
    required this.time,
    this.patientImage,
    this.doctorImage,
    this.doctorSpecialty,
    this.patientAge,
    this.notes,
    this.location,
    this.tokenNumber,
    this.queuePosition,
    required this.doctorId,
    required this.patientId,
  });

  // Factory constructor to create an Appointment from a Firestore document
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientName: data['patientName'] ?? 'N/A',
      doctorName: data['doctorName'] ?? 'N/A',
      status: data['status'] ?? 'pending',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? 'N/A',
      patientImage: data['patientImage'],
      doctorImage: data['doctorImage'],
      doctorSpecialty: data['doctorSpecialty'],
      patientAge: data['patientAge'],
      notes: data['notes'],
      location: data['location'],
      tokenNumber: data['tokenNumber'],
      queuePosition: data['queuePosition'],
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
    );
  }

  // toMap() is still useful for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'doctorName': doctorName,
      'status': status,
      'date': Timestamp.fromDate(date),
      'time': time,
      'patientImage': patientImage,
      'doctorImage': doctorImage,
      'doctorSpecialty': doctorSpecialty,
      'patientAge': patientAge,
      'notes': notes,
      'location': location,
      'tokenNumber': tokenNumber,
      'queuePosition': queuePosition,
      'doctorId': doctorId,
      'patientId': patientId,
    };
  }
}