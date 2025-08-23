// views/patient/appointment_booking_page.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sehatyab/res/colors/app_colors.dart';
import 'package:sehatyab/res/components/input_field.dart';
import 'package:sehatyab/models/doctor/doctor_model/doctor_model.dart';
import 'package:sehatyab/services/notification_services/notification_services.dart';

class AppointmentBookingPage extends StatefulWidget {
  final Doctor doctor;

  const AppointmentBookingPage({Key? key, required this.doctor}) : super(key: key);

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedSlot;
  bool _isLoading = false;
  bool _isBooking = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  List<String> _availableSlots = [];
  StreamSubscription<DocumentSnapshot>? _doctorSubscription;

  // Standard time slots available all day
  final List<String> _allDaySlots = [
    '09:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '01:00 PM', '02:00 PM',
    '03:00 PM', '04:00 PM', '05:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _doctorSubscription?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      // Load doctor's basic info (for notifications)
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctor.id)
          .get();

      // Initialize with all slots available
      _availableSlots = _allDaySlots;
    } catch (e) {
      debugPrint('Error loading doctor info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctor info: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDate, selectedDay)) {
      setState(() {
        _selectedDate = selectedDay;
        _selectedSlot = null;
        _focusedDay = focusedDay;
        _availableSlots = _allDaySlots;
      });
    }
  }

  void _selectSlot(String slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  bool get _canBook => _selectedDate != null && _selectedSlot != null;

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate() || !_canBook) return;

    setState(() => _isBooking = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Get patient details
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(currentUser.uid)
          .get();

      if (!patientDoc.exists) throw Exception('Patient data not found');

      // First check if slot is already booked
      final isAvailable = await _checkSlotAvailability();
      if (!isAvailable) {
        _showSlotUnavailableDialog();
        return;
      }

      // Generate token number
      final tokenNumber = await _generateTokenNumber();

      // Create appointment
      final appointmentRef = FirebaseFirestore.instance.collection('appointments').doc();

      await appointmentRef.set({
        'id': appointmentRef.id,
        'doctorId': widget.doctor.id,
        'doctorName': widget.doctor.name,
        'doctorImage': widget.doctor.image,
        'doctorSpecialty': widget.doctor.specialty,
        'patientId': currentUser.uid,
        'patientName': patientDoc.data()?['name'] ?? 'Patient',
        'patientImage': patientDoc.data()?['imageUrl'],
        'date': Timestamp.fromDate(_selectedDate!),
        'time': _selectedSlot!,
        'status': 'pending',
        'tokenNumber': tokenNumber,
        'queuePosition': 0, // Will be calculated in real-time
        'isActive': false,
        'notes': _notesController.text,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Notify doctor
      await NotificationService.sendAppointmentNotification(
        userId: widget.doctor.id,
        title: 'New Appointment Request',
        body: 'You have a new appointment request from ${patientDoc.data()?['name'] ?? 'Patient'}',
        data: {
          'type': 'new_appointment',
          'appointmentId': appointmentRef.id,
        },
      );

      // Show success dialog with token info
      _showBookingSuccessDialog(tokenNumber);

    } catch (e) {
      debugPrint('Booking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }

  Future<int> _generateTokenNumber() async {
    try {
      // Get the doctor's current token counter
      final doctorRef = FirebaseFirestore.instance.collection('doctors').doc(widget.doctor.id);
      final doctorDoc = await doctorRef.get();

      // Increment the token counter
      int currentToken = (doctorDoc.data()?['currentToken'] ?? 0) + 1;

      // Update the doctor's token counter
      await doctorRef.update({'currentToken': currentToken});

      return currentToken;
    } catch (e) {
      debugPrint('Error generating token: $e');
      // Fallback - use timestamp as token
      return DateTime.now().millisecondsSinceEpoch % 1000;
    }
  }

  Future<bool> _checkSlotAvailability() async {
    try {
      if (_selectedDate == null || _selectedSlot == null) return false;

      // Check against existing appointments
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate!))
          .where('time', isEqualTo: _selectedSlot!)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Slot availability check error: $e');
      return false;
    }
  }

  void _showSlotUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slot Already Booked'),
        content: const Text('The selected time slot has already been booked. Please choose another time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBookingSuccessDialog(int tokenNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Booked!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your appointment has been successfully booked.'),
            const SizedBox(height: 16),
            Text(
              'Your Token Number: $tokenNumber',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can track your appointment status and queue position in the "My Appointments" section.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
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
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorCard(),
              const SizedBox(height: 24),
              _buildCalendarSection(),
              if (_selectedDate != null) ...[
                const SizedBox(height: 24),
                _buildTimeSlotsSection(),
              ],
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
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 Weeks',
                CalendarFormat.week: 'Week',
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              // All future dates are enabled
              enabledDayPredicate: (day) => day.isAfter(DateTime.now().subtract(const Duration(days: 1))),
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
                formatButtonVisible: true,
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
                titleCentered: true,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekendStyle: TextStyle(
                  color: Colors.red.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Time Slots for ${DateFormat('MMM d, yyyy').format(_selectedDate!)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSlots.map((slot) {
            return InkWell(
              onTap: () => _selectSlot(slot),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _selectedSlot == slot
                      ? AppColors.primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    color: _selectedSlot == slot ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _canBook
              ? AppColors.primaryColor
              : Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        onPressed: _canBook ? () {
          if (_formKey.currentState!.validate()) {
            _confirmBooking();
          }
        } : null,
        child: _isBooking
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
  }
}