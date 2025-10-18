// views/patient/appointment_booking_page.dart
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

  Future<void> _fetchDoctorAvailability() async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 90)); // Fetch availability for next 90 days

    FirebaseFirestore.instance
        .collection('daily_availability')
        .where('doctorId', isEqualTo: widget.doctor.id)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThan: Timestamp.fromDate(endDate))
        .snapshots()
        .listen((snapshot) {
      _dailyAvailability.clear();
      for (var doc in snapshot.docs) {
        final dailyData = DailyAvailabilityModel.fromMap(doc.data(), doc.id);
        final dateKey = DateFormat('yyyy-MM-dd').format(dailyData.date);
        _dailyAvailability[dateKey] = dailyData;
      }
    });
  }

  Future<void> _fetchTimeSlots(DateTime date) async {
    _timeSlots.clear();
    _selectedTimeSlot.value = null;

    final appointmentsSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctor.id)
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .get();

    final bookedTimeSlots = appointmentsSnapshot.docs.map((doc) => doc.data()['timeSlot'] as String?).toSet();

    // Generate a list of standard time slots for the day
    List<String> allTimeSlots = [
      '09:00 AM - 10:00 AM',
      '10:00 AM - 11:00 AM',
      '11:00 AM - 12:00 PM',
      '02:00 PM - 03:00 PM',
      '03:00 PM - 04:00 PM',
      '04:00 PM - 05:00 PM',
    ];

    // Filter out the booked time slots
    final availableTimeSlots = allTimeSlots.where((slot) => !bookedTimeSlots.contains(slot)).toList();

    _timeSlots.assignAll(availableTimeSlots);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay.value = selectedDay;
    _focusedDay.value = focusedDay;

    final dateKey = _formatDateKey(selectedDay);
    final dailyData = _dailyAvailability[dateKey];

    if (dailyData?.status == 'unavailable' || dailyData == null) {
      Get.snackbar('Unavailable', 'Dr. ${widget.doctor.name} is not available on this day.',
          snackPosition: SnackPosition.BOTTOM);
      _selectedDay.value = null; // Unselect the day
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

    _fetchTimeSlots(selectedDay);
  }

  Future<void> _confirmBooking() async {
    if (_selectedDay.value == null || _selectedTimeSlot.value == null) {
      Get.snackbar('Error', 'Please select both a date and a time slot.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    _bookingStatus.value = true;
    final dateKey = _formatDateKey(_selectedDay.value!);
    final dailyData = _dailyAvailability[dateKey];
    final currentUser = FirebaseAuth.instance.currentUser;

    try {
      if (currentUser == null) throw Exception('User not logged in');
      if (dailyData == null || dailyData.status == 'unavailable') {
        throw Exception('Doctor is not available on the selected date.');
      }
      if (dailyData.isFull()) {
        throw Exception('All appointment slots for this day are booked.');
      }

      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(currentUser.uid)
          .get();
      if (!patientDoc.exists) throw Exception('Patient data not found');

      // Use a Firestore Transaction for atomic updates
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final dailyAvailabilityRef = FirebaseFirestore.instance.collection('daily_availability').doc(dailyData.id);
        final dailyAvailabilitySnapshot = await transaction.get(dailyAvailabilityRef);

        if (!dailyAvailabilitySnapshot.exists) {
          throw Exception("Daily availability data no longer exists.");
        }

        final updatedDailyData = DailyAvailabilityModel.fromMap(dailyAvailabilitySnapshot.data()!, dailyAvailabilitySnapshot.id);

        // Final check within the transaction
        if (updatedDailyData.isFull()) {
          throw Exception("All appointment slots for this day are now full. Please select another day.");
        }

        // 1. Increment appointmentsCount
        final newAppointmentsCount = updatedDailyData.appointmentsCount + 1;
        transaction.update(dailyAvailabilityRef, {'appointmentsCount': newAppointmentsCount});

        // 2. Create the new appointment document
        final appointmentRef = FirebaseFirestore.instance.collection('appointments').doc();
        transaction.set(appointmentRef, {
          'id': appointmentRef.id,
          'doctorId': widget.doctor.id,
          'doctorName': widget.doctor.name,
          'doctorImage': widget.doctor.image,
          'doctorSpecialty': widget.doctor.specialty,
          'patientId': currentUser.uid,
          'patientName': patientDoc.data()?['name'] ?? 'Patient',
          'patientImage': patientDoc.data()?['imageUrl'],
          'date': Timestamp.fromDate(_selectedDay.value!),
          'timeSlot': _selectedTimeSlot.value, // Added time slot
          'notes': _notesController.text,
          'status': 'pending',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      });

      // Notify doctor
      await NotificationService.sendAppointmentNotification(
        userId: widget.doctor.id,
        title: 'New Appointment Request',
        body: 'You have a new appointment request from ${patientDoc.data()?['name'] ?? 'Patient'}',
        data: {
          'type': 'new_appointment',
          'appointmentId': '', // Note: Appointment ID is not available here due to transaction
        },
      );

      _showBookingSuccessDialog();
    } catch (e) {
      Get.snackbar('Booking Failed', e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      debugPrint('Booking error: $e');
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
              Get.back(); // Closes the dialog
              Get.back(); // Navigates back to the doctor profile page
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showAvailabilityDetailsDialog(BuildContext context, DateTime date) {
    final dateKey = _formatDateKey(date);
    final DailyAvailabilityModel? dailyData = _dailyAvailability[dateKey];
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
      patientInfo = 'Patient Limit: ${dailyData.patientLimit}\nBooked: ${dailyData.appointmentsCount}';
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(widget.doctor.image),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${widget.doctor.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.doctor.specialty,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${widget.doctor.rating.toStringAsFixed(1)}'),
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
        const Text(
          'Select Date',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Obx(() {
            return TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay.value,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay.value, day),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay.value = focusedDay;
              },
              onDayLongPressed: (date, focusedDay) {
                _showAvailabilityDetailsDialog(context, date);
              },
              enabledDayPredicate: (day) {
                final dateKey = _formatDateKey(day);
                final dailyData = _dailyAvailability[dateKey];
                final isAvailable = dailyData?.status == 'available' && !dailyData!.isFull();
                return isAvailable && !day.isBefore(DateTime.now());
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final dateKey = _formatDateKey(date);
                  final dailyData = _dailyAvailability[dateKey];
                  Color? dotColor;

                  if (dailyData == null || dailyData.status == 'unavailable') {
                    dotColor = Colors.red; // All dates are unavailable by default
                  } else if (dailyData.isFull()) {
                    dotColor = Colors.orange;
                  } else {
                    dotColor = Colors.green;
                  }

                  // Only show markers for today and future dates
                  if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                        width: 8.0,
                        height: 8.0,
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
                selectedDecoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(
                  color: Colors.red.withOpacity(0.8),
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekendStyle: TextStyle(
                  color: Colors.red.withOpacity(0.8),
                ),
              ),
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
        const Text(
          'Select Time Slot',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          return Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot.value == slot;
              return GestureDetector(
                onTap: () {
                  _selectedTimeSlot.value = slot;
                },
                child: Chip(
                  label: Text(slot),
                  backgroundColor: isSelected ? AppColors.primaryColor : Colors.grey[200],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
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
        const Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        Text(
          'Maximum 500 characters',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text(
            'CONFIRM APPOINTMENT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    });
  }

  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}