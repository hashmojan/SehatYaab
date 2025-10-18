// models/availability_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

// -------- Static Schedule --------
class StaticScheduleModel extends Equatable {
  final String doctorId;
  final Map<String, List<String>> workingDays; // {day: [time slots]}
  final int appointmentDuration; // in minutes

  const StaticScheduleModel({
    required this.doctorId,
    required this.workingDays,
    this.appointmentDuration = 30,
  });

  factory StaticScheduleModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StaticScheduleModel(
      doctorId: map['doctorId'] as String,
      workingDays: _convertWorkingDays(map['workingDays']),
      appointmentDuration: map['appointmentDuration'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'workingDays': workingDays,
      'appointmentDuration': appointmentDuration,
    };
  }

  static Map<String, List<String>> _convertWorkingDays(dynamic data) {
    final Map<String, List<String>> result = {};
    if (data is Map) {
      data.forEach((key, value) {
        if (value is List) {
          result[key.toString()] = List<String>.from(value);
        }
      });
    }
    return result;
  }

  @override
  List<Object?> get props => [doctorId, workingDays, appointmentDuration];
}

// -------- Daily Availability --------
class DailyAvailabilityModel extends Equatable {
  final String id; // doctorId_YYYY-MM-DD
  final String doctorId;
  final DateTime date;
  final String status; // 'available', 'unavailable'
  final int patientLimit;
  final int appointmentsCount;
  final List<String> availableTimeSlots; // optional: override static schedule

  const DailyAvailabilityModel({
    required this.id,
    required this.doctorId,
    required this.date,
    this.status = 'unavailable',
    this.patientLimit = 20, // ✅ default 20
    this.appointmentsCount = 0,
    this.availableTimeSlots = const [],
  });

  // Generate an ID automatically if needed
  factory DailyAvailabilityModel.create({
    required String doctorId,
    required DateTime date,
    String status = 'unavailable',
    int patientLimit = 20,
  }) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return DailyAvailabilityModel(
      id: '${doctorId}_$dateKey',
      doctorId: doctorId,
      date: date,
      status: status,
      patientLimit: patientLimit,
      appointmentsCount: 0,
      availableTimeSlots: const [],
    );
  }

  // From Firestore
  factory DailyAvailabilityModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DailyAvailabilityModel(
      id: documentId,
      doctorId: map['doctorId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] as String? ?? 'unavailable',
      patientLimit: map['patientLimit'] as int? ?? 20,
      appointmentsCount: map['appointmentsCount'] as int? ?? 0,
      availableTimeSlots: List<String>.from(map['availableTimeSlots'] as List? ?? []),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'date': Timestamp.fromDate(date),
      'status': status,
      'patientLimit': patientLimit,
      'appointmentsCount': appointmentsCount,
      'availableTimeSlots': availableTimeSlots,
    };
  }

  bool isFull() => appointmentsCount >= patientLimit;

  DailyAvailabilityModel copyWith({
    String? id,
    String? doctorId,
    DateTime? date,
    String? status,
    int? patientLimit,
    int? appointmentsCount,
    List<String>? availableTimeSlots,
  }) {
    return DailyAvailabilityModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      status: status ?? this.status,
      patientLimit: patientLimit ?? this.patientLimit,
      appointmentsCount: appointmentsCount ?? this.appointmentsCount,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
    );
  }

  @override
  List<Object?> get props => [
    id,
    doctorId,
    date,
    status,
    patientLimit,
    appointmentsCount,
    availableTimeSlots,
  ];
}
