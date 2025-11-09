import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../view_model/controller/appointment_controller/patient_controller/myappointments_controller.dart';

class AppointmentDetailsPage extends StatefulWidget {
  const AppointmentDetailsPage({Key? key}) : super(key: key);

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  late Map<String, dynamic> appointment;
  late Stream<DocumentSnapshot> _appointmentStream;
  late Stream<DocumentSnapshot> _doctorStream;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    appointment = Get.arguments as Map<String, dynamic>;
    _initializeStreams();
  }

  void _initializeStreams() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final apptId = appointment['id'] as String;
    final doctorId = appointment['doctorId'] as String;

    // Prefer the patient's subcollection (no composite index, always available)
    final patientApptRef = _firestore
        .collection('patients')
        .doc(uid)
        .collection('appointments')
        .doc(apptId);

    _appointmentStream = patientApptRef.snapshots();

    // doctor stream for live queue/currentToken (if you use it)
    _doctorStream = _firestore.collection('doctors').doc(doctorId).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final String doctorName = appointment['doctorName'] ?? 'N/A';
    final String doctorSpecialty = appointment['doctorSpecialty'] ?? 'N/A';
    final String? doctorImage = appointment['doctorImage'];
    final String notes = appointment['notes'] ?? 'No notes provided.';
    final String patientName = appointment['patientName'] ?? 'Unknown Patient';

    DateTime? appointmentDate;
    if (appointment['date'] is Timestamp) {
      appointmentDate = (appointment['date'] as Timestamp).toDate();
    } else if (appointment['date'] is String) {
      appointmentDate = DateTime.tryParse(appointment['date']);
    }
    final String formattedDate = appointmentDate != null
        ? DateFormat('MMM dd, yyyy').format(appointmentDate)
        : 'Date not available';

    // We store 'timeSlot' (not 'time') when booking
    final String initialStatus = appointment['status'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _doctorStream,
        builder: (context, doctorSnapshot) {
          if (!doctorSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doctorData = doctorSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final currentToken = doctorData['currentToken'] ?? 0;

          return StreamBuilder<DocumentSnapshot>(
            stream: _appointmentStream,
            builder: (context, appointmentSnapshot) {
              if (!appointmentSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final live = appointmentSnapshot.data!.data() as Map<String, dynamic>? ?? appointment;
              final updatedStatus = (live['status'] ?? initialStatus) as String;
              final tokenNumber = (live['tokenNumber'] as num?)?.toInt() ?? 0;
              final timeSlot = (live['timeSlot'] ?? live['time'] ?? 'Time not specified') as String;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundImage: doctorImage != null
                                      ? NetworkImage(doctorImage)
                                      : const AssetImage('assets/default_doctor.png') as ImageProvider,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Dr. $doctorName',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(doctorSpecialty, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 30),
                            _buildDetailRow(Icons.person, 'Patient Name:', patientName),
                            const SizedBox(height: 12),
                            _buildDetailRow(Icons.calendar_today, 'Date:', formattedDate),
                            const SizedBox(height: 12),
                            _buildDetailRow(Icons.access_time, 'Time:', timeSlot),
                            const SizedBox(height: 12),
                            if (tokenNumber > 0)
                              _buildDetailRow(Icons.confirmation_number, 'Your Token No.:', '$tokenNumber'),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.info_outline,
                              'Status:',
                              updatedStatus.toUpperCase(),
                              statusColor: _getStatusColor(updatedStatus),
                            ),
                            if (tokenNumber > 0 &&
                                updatedStatus != 'completed' &&
                                updatedStatus != 'cancelled')
                              _buildQueueInfo(currentToken, tokenNumber),
                            const SizedBox(height: 12),
                            const Text('Additional Notes:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(notes),
                          ],
                        ),
                      ),
                    ),
                    if (updatedStatus == 'pending' || updatedStatus == 'confirmed')
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: () => _showCancelDialog(live['id'] as String, live['doctorId'] as String),
                                child: const Text('Cancel Appointment'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: statusColor,
              fontWeight: statusColor != null ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueInfo(int currentToken, int myToken) {
    final status = currentToken >= myToken ? 'In Progress' : 'Waiting';
    final color = currentToken >= myToken ? Colors.orange : Colors.blue;
    final icon = currentToken >= myToken ? Icons.timer : Icons.hourglass_bottom;

    final patientsAhead = (myToken - currentToken - 1).clamp(0, 1 << 30);
    final estimatedMinutes = patientsAhead * 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              Text('(Current Token: $currentToken)', style: TextStyle(color: color)),
            ],
          ),
        ),
        if (patientsAhead > 0) ...[
          const SizedBox(height: 16),
          Text('Estimated Wait Time:', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text('$patientsAhead patients ahead (~$estimatedMinutes mins)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  Future<void> _showCancelDialog(String appointmentId, String doctorId) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final c = Get.isRegistered<MyAppointmentsController>()
                    ? Get.find<MyAppointmentsController>()
                    : Get.put(MyAppointmentsController());
                await c.cancelAppointment(appointmentId, doctorId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled successfully')),
                );
                Get.back(); // go back after cancellation
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to cancel: $e')),
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
