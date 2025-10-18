// // models/doctor/schedule_slot/schedule_slot.dart
//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class ScheduleSlot {
//   final String id; // Unique ID for the slot
//   final String doctorId; // Add doctorId to link to the doctor
//   final String day;
//   final   date;
//
//   final String startTime;
//   final String endTime;
//   final int maxAppointments;
//   final bool isAvailable;
//   final int bookedAppointments; // To track current bookings
//
//   ScheduleSlot({
//     required this.id,
//     required this.doctorId,
//     required this.day,
//     required this.date,
//
//     required this.startTime,
//     required this.endTime,
//     required this.maxAppointments,
//     required this.isAvailable,
//     this.bookedAppointments = 0, // Initialize to 0
//   });
//
//   // Factory constructor for creating a ScheduleSlot from a Firestore document
//   factory ScheduleSlot.fromFirestore(DocumentSnapshot doc) {
//     Map data = doc.data() as Map<String, dynamic>;
//     return ScheduleSlot(
//       id: doc.id,
//       doctorId: data['doctorId'] ?? '', // Ensure doctorId is retrieved
//       day: data['day'] ?? '',
//       startTime: data['startTime'] ?? '',
//       endTime: data['endTime'] ?? '',
//       date: data['date'] ?? '',
//       maxAppointments: data['maxAppointments'] ?? 0,
//       isAvailable: data['isAvailable'] ?? false,
//       bookedAppointments: data['bookedAppointments'] ?? 0,
//     );
//   }
//
//   // Convert ScheduleSlot to a Map for Firestore
//   Map<String, dynamic> toFirestore() {
//     return {
//       'doctorId': doctorId,
//       'day': day,
//       'startTime': startTime,
//       'endTime': endTime,
//       'maxAppointments': maxAppointments,
//       'isAvailable': isAvailable,
//       'bookedAppointments': bookedAppointments,
//       'createdAt': FieldValue.serverTimestamp(), // Optional: for ordering/tracking
//     };
//   }
//
//   // Method to create a copy with updated values
//   ScheduleSlot copyWith({
//     String? id,
//     String? doctorId,
//     String? day,
//     String? startTime,
//     String? endTime,
//     int? maxAppointments,
//     bool? isAvailable,
//     int? bookedAppointments,
//   }) {
//     return ScheduleSlot(
//       id: id ?? this.id,
//       doctorId: doctorId ?? this.doctorId,
//       day: day ?? this.day,
//       date: date ?? this.date,
//       startTime: startTime ?? this.startTime,
//       endTime: endTime ?? this.endTime,
//       maxAppointments: maxAppointments ?? this.maxAppointments,
//       isAvailable: isAvailable ?? this.isAvailable,
//       bookedAppointments: bookedAppointments ?? this.bookedAppointments,
//     );
//   }
// }