import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/doctor/appointment/appointment_model.dart';
import '../../../view_model/controller/appointment_controller/doctor_controller/doctor_appointment_controller.dart';

class AppointmentDiaryPage extends StatefulWidget {
  @override
  State<AppointmentDiaryPage> createState() => _AppointmentDiaryPageState();
}

class _AppointmentDiaryPageState extends State<AppointmentDiaryPage> {
  final DoctorAppointmentController controller = Get.find();
  final RxString _filter = 'all'.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: controller.doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data!.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .where((appt) => _filter.value == 'all' ||
              (_filter.value == 'upcoming' && (appt.status == 'pending' || appt.status == 'confirmed')) ||
              (_filter.value == 'past' && appt.status == 'completed') ||
              (_filter.value == 'cancelled' && appt.status == 'cancelled'))
              .toList();

          if (appointments.isEmpty) {
            return const Center(child: Text('No appointments found'));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return AppointmentCard(appointment: appointment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateAppointment(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Appointments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterRadio('all', 'All Appointments'),
            _buildFilterRadio('upcoming', 'Upcoming'),
            _buildFilterRadio('past', 'Past Appointments'),
            _buildFilterRadio('cancelled', 'Cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRadio(String value, String title) {
    return Obx(() => RadioListTile<String>(
      value: value,
      groupValue: _filter.value,
      title: Text(title),
      onChanged: (value) {
        Navigator.pop(context);
        _filter.value = value!;
      },
    ));
  }

  void _navigateToCreateAppointment(BuildContext context) {
    // Implement navigation to appointment creation screen
  }
}

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appointment.patientName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                // Text(DateFormat('MMM d, yyyy').format(appointment.date)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(appointment.time),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                appointment.status.toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _getStatusColor(appointment.status),
            ),
            if (appointment.status != 'cancelled') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.find<DoctorAppointmentController>()
                      .cancelAppointment(appointment.id),
                  child: const Text('Cancel Appointment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      case 'completed':
        return Colors.blue.shade100;
      case 'pending':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}