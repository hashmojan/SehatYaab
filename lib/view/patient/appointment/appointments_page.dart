// views/patient/appointments_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../res/components/cards/appointment_card.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _appointmentsStream;

  @override
  void initState() {
    super.initState();
    _appointmentsStream = _getAppointmentsStream();
  }

  Stream<QuerySnapshot> _getAppointmentsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: userId)
        .orderBy('date')
        .orderBy('time')
        .snapshots();
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No appointments booked yet'));
          }

          // Calculate queue positions for each appointment
          final appointments = snapshot.data!.docs;
          final now = DateTime.now();

          // Group appointments by date and doctor
          final Map<String, List<DocumentSnapshot>> groupedAppointments = {};

          for (final appointment in appointments) {
            final data = appointment.data() as Map<String, dynamic>;
            if (data['status'] != 'pending' && data['status'] != 'confirmed') continue;

            final date = (data['date'] as Timestamp).toDate();
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            final doctorId = data['doctorId'];
            final groupKey = '$dateKey-$doctorId';

            groupedAppointments.putIfAbsent(groupKey, () => []).add(appointment);
          }

          // Sort each group by time and calculate queue positions
          for (final group in groupedAppointments.values) {
            group.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['time'];
              final bTime = (b.data() as Map<String, dynamic>)['time'];
              return aTime.compareTo(bTime);
            });

            for (int i = 0; i < group.length; i++) {
              final data = group[i].data() as Map<String, dynamic>;
              data['queuePosition'] = i + 1;

              // Mark as active if it's the current or next appointment
              final appointmentDate = (data['date'] as Timestamp).toDate();
              final isToday = appointmentDate.year == now.year &&
                  appointmentDate.month == now.month &&
                  appointmentDate.day == now.day;

              if (isToday && i == 0) {
                data['isActive'] = true;
              } else {
                data['isActive'] = false;
              }
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var appointment = appointments[index];
              var data = appointment.data() as Map<String, dynamic>;

              return AppointmentCard(
                appointment: data,
                onCancel: data['status'] == 'pending' || data['status'] == 'confirmed'
                    ? () => _cancelAppointment(data['id'])
                    : null,
                showQueueInfo: true,
              );
            },
          );
        },
      ),
    );
  }
}