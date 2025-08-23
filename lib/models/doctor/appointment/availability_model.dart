// models/availability_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

@immutable
class AvailabilityModel extends Equatable {
  final String doctorId;
  final Map<String, List<String>> workingDays; // {day: [time slots]}
  final List<DateTime> nonWorkingDates;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String timeZone;
  final int appointmentDuration; // in minutes
  final String? locationId;

  const AvailabilityModel({
    required this.doctorId,
    required this.workingDays,
    required this.nonWorkingDates,
    required this.createdAt,
    required this.updatedAt,
    this.timeZone = 'UTC',
    this.appointmentDuration = 30,
    this.locationId,
  });

  // Convert model to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'workingDays': workingDays,
      'nonWorkingDates': nonWorkingDates.map((date) => Timestamp.fromDate(date)).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'timeZone': timeZone,
      'appointmentDuration': appointmentDuration,
      'locationId': locationId,
    };
  }

  // Create model from Firestore document
  factory AvailabilityModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AvailabilityModel(
      doctorId: map['doctorId'] as String,
      workingDays: _convertWorkingDays(map['workingDays']),
      nonWorkingDates: _convertNonWorkingDates(map['nonWorkingDates']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      timeZone: map['timeZone'] as String? ?? 'UTC',
      appointmentDuration: map['appointmentDuration'] as int? ?? 30,
      locationId: map['locationId'] as String?,
    );
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

  static List<DateTime> _convertNonWorkingDates(dynamic data) {
    if (data is List) {
      return data
          .whereType<Timestamp>()
          .map((ts) => ts.toDate())
          .toList();
    }
    return [];
  }

  // Create a copy of the availability with updated values
  AvailabilityModel copyWith({
    String? doctorId,
    Map<String, List<String>>? workingDays,
    List<DateTime>? nonWorkingDates,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? timeZone,
    int? appointmentDuration,
    String? locationId,
  }) {
    return AvailabilityModel(
      doctorId: doctorId ?? this.doctorId,
      workingDays: workingDays ?? this.workingDays,
      nonWorkingDates: nonWorkingDates ?? this.nonWorkingDates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeZone: timeZone ?? this.timeZone,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      locationId: locationId ?? this.locationId,
    );
  }

  // Check if a specific date is available
  bool isDateAvailable(DateTime date) {
    final weekday = _getWeekdayString(date);
    return workingDays.containsKey(weekday) &&
        !nonWorkingDates.any((d) => _isSameDate(d, date));
  }

  // Get available time slots for a specific date
  List<String> getTimeSlotsForDate(DateTime date) {
    if (!isDateAvailable(date)) return [];
    return workingDays[_getWeekdayString(date)] ?? [];
  }

  // Validate the availability configuration
  static List<String> validateAvailability(Map<String, List<String>> workingDays) {
    final errors = <String>[];
    const validDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    if (workingDays.isEmpty) {
      errors.add('At least one working day must be selected');
    }

    workingDays.forEach((day, slots) {
      if (!validDays.contains(day)) {
        errors.add('Invalid day: $day');
      }

      final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
      for (final slot in slots) {
        if (!timeRegex.hasMatch(slot)) {
          errors.add('Invalid time format: $slot');
        }
      }

      // Check for sorted and non-overlapping slots
      final sortedSlots = _sortTimeSlots(slots);
      if (!listEquals(slots, sortedSlots)) {
        errors.add('Time slots must be in chronological order: $day');
      }

      for (int i = 1; i < sortedSlots.length; i++) {
        if (_timeToMinutes(sortedSlots[i]) <= _timeToMinutes(sortedSlots[i-1])) {
          errors.add('Overlapping time slots: ${sortedSlots[i-1]} - ${sortedSlots[i]}');
        }
      }
    });

    return errors.toSet().toList(); // Remove duplicates
  }

  // Helper methods
  static List<String> _sortTimeSlots(List<String> slots) {
    return List.from(slots)
      ..sort((a, b) => _timeToMinutes(a).compareTo(_timeToMinutes(b)));
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _getWeekdayString(DateTime date) {
    return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    [date.weekday - 1];
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  List<Object?> get props => [
    doctorId,
    workingDays,
    nonWorkingDates,
    createdAt,
    updatedAt,
    timeZone,
    appointmentDuration,
    locationId,
  ];

  @override
  String toString() => '''
    AvailabilityModel(
      doctorId: $doctorId,
      workingDays: $workingDays,
      nonWorkingDates: $nonWorkingDates,
      timeZone: $timeZone,
      appointmentDuration: $appointmentDuration,
      locationId: $locationId,
      createdAt: $createdAt,
      updatedAt: $updatedAt
    )
  ''';

  static empty() {}
}

// Extension for time slot calculations
extension AvailabilityExtensions on AvailabilityModel {
  List<DateTime> generateAvailableSlots(DateTime date) {
    final slots = <DateTime>[];
    final weekday = AvailabilityModel._getWeekdayString(date);
    final timeSlots = workingDays[weekday] ?? [];

    for (final slot in timeSlots) {
      final timeParts = slot.split(':');
      final hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);

      slots.add(DateTime(
        date.year,
        date.month,
        date.day,
        hours,
        minutes,
      ));
    }

    return slots;
  }

  bool isSlotAvailable(DateTime date, String time) {
    final weekday = AvailabilityModel._getWeekdayString(date);
    return workingDays[weekday]?.contains(time) ?? false;
  }
}