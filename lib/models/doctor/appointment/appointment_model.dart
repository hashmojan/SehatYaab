import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorImage;
  final String doctorSpecialty;
  final String patientId;
  final String patientName;
  final String? patientImage;
  final DateTime date;
  final String time;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? notes;
  final String? diagnosis;
  final String? prescription;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? location;
  final String? appointmentType; // 'checkup', 'followup', 'emergency', etc.
  final int? durationMinutes;
  final bool? isPaid;
  final double? fee;
  final String? paymentMethod;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.doctorSpecialty,
    required this.patientId,
    required this.patientName,
    this.patientImage,
    required this.date,
    required this.time,
    this.status = 'pending',
    this.notes,
    this.diagnosis,
    this.prescription,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.appointmentType,
    this.durationMinutes = 30,
    this.isPaid = false,
    this.fee,
    this.paymentMethod,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorImage': doctorImage,
      'doctorSpecialty': doctorSpecialty,
      'patientId': patientId,
      'patientName': patientName,
      'patientImage': patientImage,
      'date': Timestamp.fromDate(date),
      'time': time,
      'status': status,
      'notes': notes,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'appointmentType': appointmentType,
      'durationMinutes': durationMinutes,
      'isPaid': isPaid,
      'fee': fee,
      'paymentMethod': paymentMethod,
    };
  }

  // Create from Firestore document
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? 'Unknown Doctor',
      doctorImage: data['doctorImage'] ?? 'assets/default_doctor.png',
      doctorSpecialty: data['doctorSpecialty'] ?? 'General Practitioner',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Unknown Patient',
      patientImage: data['patientImage'],
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      diagnosis: data['diagnosis'],
      prescription: data['prescription'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      location: data['location'],
      appointmentType: data['appointmentType'],
      durationMinutes: data['durationMinutes'] ?? 30,
      isPaid: data['isPaid'] ?? false,
      fee: data['fee']?.toDouble(),
      paymentMethod: data['paymentMethod'],
    );
  }

  // Helper methods
  String get formattedDate => DateFormat('MMM d, yyyy').format(date);
  String get formattedTime => time;
  String get formattedDateTime => '$formattedDate at $formattedTime';
  String get durationFormatted => '${durationMinutes ?? 30} mins';

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  // Copy with method for updates
  Appointment copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? doctorImage,
    String? doctorSpecialty,
    String? patientId,
    String? patientName,
    String? patientImage,
    DateTime? date,
    String? time,
    String? status,
    String? notes,
    String? diagnosis,
    String? prescription,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
    String? appointmentType,
    int? durationMinutes,
    bool? isPaid,
    double? fee,
    String? paymentMethod,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorImage: doctorImage ?? this.doctorImage,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientImage: patientImage ?? this.patientImage,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      location: location ?? this.location,
      appointmentType: appointmentType ?? this.appointmentType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isPaid: isPaid ?? this.isPaid,
      fee: fee ?? this.fee,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  String toString() {
    return 'Appointment(id: $id, patient: $patientName, doctor: $doctorName, date: $formattedDate, time: $time, status: $status)';
  }
}