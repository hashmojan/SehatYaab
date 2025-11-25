import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../models/doctor/appointment/availability_model.dart';
import '../../../models/doctor/doctor_model/doctor_model.dart';
import '../../../res/colors/app_colors.dart';
import '../../../res/components/input_field.dart';
import '../../../services/notification_services/notification_services.dart';

class AppointmentBookingPage extends StatefulWidget {
  final Doctor doctor;

  const AppointmentBookingPage({Key? key, required this.doctor}) : super(key: key);

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _focusedDay = DateTime.now().obs;
  final _selectedDay = Rx<DateTime?>(null);
  final _bookingStatus = false.obs;
  final _selectedTimeSlot = Rx<String?>(null);
  final _timeSlots = <String>[].obs;

  final RxMap<String, DailyAvailabilityModel> _dailyAvailability = RxMap();

  static String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    _fetchDoctorAvailability();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Fetch availability from /doctors/{doctorId}/daily_availability
  Future<void> _fetchDoctorAvailability() async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 90));

    FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctor.id)
        .collection('daily_availability')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('date')
        .snapshots()
        .listen((snapshot) {
      _dailyAvailability.clear();
      for (var doc in snapshot.docs) {
        final dailyData = DailyAvailabilityModel.fromMap(doc.data(), doc.id);
        _dailyAvailability[dailyData.dateKey] = dailyData;
      }
      // Trigger rebuild
      setState(() {});
    }, onError: (e) {
      Get.snackbar('Availability Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    });
  }

  /// Prefer per-day custom slots if available; else use defaults. Booked slots removed.
  Future<void> _fetchTimeSlots(DateTime date) async {
    _timeSlots.clear();
    _selectedTimeSlot.value = null;

    final key = _dateKey(date);
    final daily = _dailyAvailability[key];

    final baseSlots = (daily?.timeSlots != null && daily!.timeSlots!.isNotEmpty)
        ? List<String>.from(daily.timeSlots!)
        : <String>[
      '09:00 AM - 10:00 AM',
      '10:00 AM - 11:00 AM',
      '11:00 AM - 12:00 PM',
      '02:00 PM - 03:00 PM',
      '03:00 PM - 04:00 PM',
      '04:00 PM - 05:00 PM',
    ];

    // Read booked slots from /doctors/{doctorId}/appointments (single equality filter)
    final bookedSnap = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(widget.doctor.id)
        .collection('appointments')
        .where('dateKey', isEqualTo: key)
        .get();

    final booked = bookedSnap.docs
        .map((d) => d.data()['timeSlot'] as String?)
        .where((s) => s != null)
        .cast<String>()
        .toSet();

    _timeSlots.assignAll(baseSlots.where((s) => !booked.contains(s)).toList());
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay.value = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    _focusedDay.value = focusedDay;

    final key = _dateKey(_selectedDay.value!);
    final dailyData = _dailyAvailability[key];

    if (dailyData == null || dailyData.status == 'unavailable') {
      Get.snackbar('Unavailable', 'Dr. ${widget.doctor.name} is not available on this day.',
          snackPosition: SnackPosition.BOTTOM);
      _selectedDay.value = null;
      _timeSlots.clear();
      _selectedTimeSlot.value = null;
      return;
    }

    if (dailyData.isFull()) {
      Get.snackbar('Fully Booked', 'All appointment slots for this day are booked.',
          snackPosition: SnackPosition.BOTTOM);
      _selectedDay.value = null;
      _timeSlots.clear();
      _selectedTimeSlot.value = null;
      return;
    }

    _fetchTimeSlots(_selectedDay.value!);
  }

  Future<void> _confirmBooking() async {
    if (_selectedDay.value == null || _selectedTimeSlot.value == null) {
      Get.snackbar('Error', 'Please select both a date and a time slot.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    _bookingStatus.value = true;
    final DateTime day = _selectedDay.value!;
    final String key = _dateKey(day);
    final currentUser = FirebaseAuth.instance.currentUser;

    try {
      if (currentUser == null) throw Exception('User not logged in');

      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(currentUser.uid)
          .get();
      if (!patientDoc.exists) throw Exception('Patient data not found');

      final FirebaseFirestore db = FirebaseFirestore.instance;
      final dailyRef = db
          .collection('doctors')
          .doc(widget.doctor.id)
          .collection('daily_availability')
          .doc(key);

      final doctorApptColl =
      db.collection('doctors').doc(widget.doctor.id).collection('appointments');
      final patientApptColl =
      db.collection('patients').doc(currentUser.uid).collection('appointments');
      final topApptColl = db.collection('appointments'); // keep legacy/top-level mirror

      await db.runTransaction((tx) async {
        // Read the daily availability atomically
        final dailySnap = await tx.get(dailyRef);
        if (!dailySnap.exists) {
          throw Exception('Doctor is not available on the selected date.');
        }

        final m = dailySnap.data()!;
        final model = DailyAvailabilityModel.fromMap(m, dailySnap.id);

        if (model.status == 'unavailable') {
          throw Exception('Doctor is not available on the selected date.');
        }
        if (model.isFull()) {
          throw Exception('All appointment slots for this day are booked.');
        }

        // Ensure the chosen slot is still free
        final bookedSnap = await doctorApptColl.where('dateKey', isEqualTo: key).get();
        final booked = bookedSnap.docs
            .map((d) => d.data()['timeSlot'] as String?)
            .where((s) => s != null)
            .cast<String>()
            .toSet();
        if (booked.contains(_selectedTimeSlot.value)) {
          throw Exception('Selected time slot has just been booked. Pick another slot.');
        }

        // Increment count and create appointment (same ID across mirrors)
        final newCount = model.appointmentsCount + 1;
        tx.update(dailyRef, {
          'appointmentsCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final apptId = topApptColl.doc().id; // generate once

        final apptData = {
          'id': apptId,
          'doctorId': widget.doctor.id,
          'doctorName': widget.doctor.name,
          'doctorImage': widget.doctor.image,
          'doctorSpecialty': widget.doctor.specialty,
          'patientId': currentUser.uid,
          'patientName': patientDoc.data()?['name'] ?? 'Patient',
          'patientImage': patientDoc.data()?['imageUrl'],
          'date': Timestamp.fromDate(day),
          'dateKey': key, // normalized day string
          'timeSlot': _selectedTimeSlot.value,
          'notes': _notesController.text,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Doctor’s subcollection
        tx.set(doctorApptColl.doc(apptId), apptData);
        // Patient’s subcollection
        tx.set(patientApptColl.doc(apptId), apptData);
        // Legacy/top-level mirror (keeps other parts of app working)
        tx.set(topApptColl.doc(apptId), apptData);
      });

      // Notify doctor (by doctor UID)
      await NotificationService.sendAppointmentNotification(
        userId: widget.doctor.id,
        title: 'New Appointment Request',
        body: 'You have a new appointment request from ${patientDoc.data()?['name'] ?? 'Patient'}',
        data: {
          'type': 'new_appointment',
          // 'appointmentId': apptId, // If you need it, return it from above (store locally)
        },
      );

      _showBookingSuccessDialog();
    } catch (e) {
      Get.snackbar('Booking Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      _bookingStatus.value = false;
    }
  }

  void _showBookingSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Appointment Booked!'),
        content: const Text(
            'Your appointment has been successfully booked. You can review it in your "My Appointments" section.'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // dialog
              Get.back(); // go back to doctor profile
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showAvailabilityDetailsDialog(BuildContext context, DateTime date) {
    final key = _dateKey(date);
    final DailyAvailabilityModel? dailyData = _dailyAvailability[key];

    String status = 'Not Set';
    String patientInfo = '';

    if (dailyData != null) {
      if (dailyData.status == 'unavailable') {
        status = 'Unavailable';
      } else if (dailyData.isFull()) {
        status = 'Fully Booked';
      } else {
        status = 'Available';
      }
      patientInfo =
      'Patient Limit: ${dailyData.patientLimit}\nBooked: ${dailyData.appointmentsCount}';
    } else {
      status = 'Not Set (Default schedule applies)';
    }

    Get.dialog(
      AlertDialog(
        title: Text('Availability for ${DateFormat.yMMMd().format(date)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(patientInfo),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book with Dr. ${widget.doctor.name}'),
        centerTitle: true,
        backgroundColor: AppColors.lightSecondary,

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorCard(),
              const SizedBox(height: 24),
              _buildCalendarSection(),
              Obx(() {
                if (_selectedDay.value != null && _timeSlots.isNotEmpty) {
                  return Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildTimeSlotsSection(),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 24),
              _buildNotesInput(),
              const SizedBox(height: 24),
              _buildBookingButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(radius: 40, backgroundImage: NetworkImage(widget.doctor.image)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. ${widget.doctor.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.doctor.specialty,
                      style: TextStyle(color: AppColors.primaryColor, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${widget.doctor.ratingAvg}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.medical_services, color: Colors.red, size: 20),
                      Text(' ${widget.doctor.experience} yrs exp'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Obx(() {
            return TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay.value,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay.value, day),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) => _focusedDay.value = focusedDay,
              onDayLongPressed: (date, _) => _showAvailabilityDetailsDialog(context, date),
              enabledDayPredicate: (day) {
                final key = _dateKey(day);
                final daily = _dailyAvailability[key];
                final isAvailable = daily?.status == 'available' && !(daily?.isFull() ?? true);
                return isAvailable && !day.isBefore(DateTime.now());
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final key = _dateKey(date);
                  final daily = _dailyAvailability[key];
                  Color? dotColor;

                  if (daily == null || daily.status == 'unavailable') {
                    dotColor = Colors.red;
                  } else if (daily.isFull()) {
                    dotColor = Colors.orange;
                  } else {
                    dotColor = Colors.green;
                  }

                  if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      ),
                    );
                  }
                  return null;
                },
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration:
                const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                weekendTextStyle: TextStyle(color: Colors.red.withOpacity(0.8)),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              daysOfWeekStyle:
              DaysOfWeekStyle(weekendStyle: TextStyle(color: Colors.red.withOpacity(0.8))),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Time Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Obx(() {
          return Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot.value == slot;
              return GestureDetector(
                onTap: () => _selectedTimeSlot.value = slot,
                child: Chip(
                  label: Text(slot),
                  backgroundColor: isSelected ? AppColors.primaryColor : Colors.grey[200],
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryColor : Colors.transparent,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Additional Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InputField(
          controller: _notesController,
          labelText: 'Notes (optional)',
          hintText: 'Enter any symptoms or concerns...',
          maxLines: 3,
          validator: (value) {
            if (value != null && value.length > 500) {
              return 'Notes should be less than 500 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text('Maximum 500 characters', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildBookingButton() {
    return Obx(() {
      final isSelected = _selectedDay.value != null && _selectedTimeSlot.value != null;
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? AppColors.primaryColor : Colors.grey[400],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          onPressed: isSelected && !_bookingStatus.value
              ? () {
            if (_formKey.currentState!.validate()) {
              _confirmBooking();
            }
          }
              : null,
          child: _bookingStatus.value
              ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
            'CONFIRM APPOINTMENT',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    });
  }
}
