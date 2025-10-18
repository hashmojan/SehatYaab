// lib/models/doctor/appointment/appointment_model.dart
class Appointment {
  final String id;
  final String patientName;
  final String doctorName;
  final String status;
  final DateTime date; // Updated to DateTime
  final String time;
  final String? patientImage;
  final String? doctorImage;
  final String? doctorSpecialty;
  final int? patientAge;
  final String? notes;
  final String? location;
  final int? tokenNumber;
  final int? queuePosition;
  final String doctorId; // Added for clarity and use in cancel function

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
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      patientName: map['patientName'] as String,
      doctorName: map['doctorName'] as String,
      status: map['status'] as String,
      date: DateTime.parse(map['date'] as String), // Parse the string into a DateTime object
      time: map['time'] as String,
      patientImage: map['patientImage'] as String?,
      doctorImage: map['doctorImage'] as String?,
      doctorSpecialty: map['doctorSpecialty'] as String?,
      patientAge: map['patientAge'] as int?,
      notes: map['notes'] as String?,
      location: map['location'] as String?,
      tokenNumber: map['tokenNumber'] as int?,
      queuePosition: map['queuePosition'] as int?,
      doctorId: map['doctorId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'doctorName': doctorName,
      'status': status,
      'date': date.toIso8601String(), // Convert DateTime to a string for storage
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
    };
  }
}