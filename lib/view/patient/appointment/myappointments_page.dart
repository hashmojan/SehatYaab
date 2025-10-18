// views/patient/appointments_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../res/components/cards/appointment_card.dart';
import '../../../view_model/controller/appointment_controller/patient_controller/myappointments_controller.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final controller = Get.put(MyAppointmentsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.appointments.isEmpty) {
          return const Center(child: Text('No appointments booked yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.appointments.length,
          itemBuilder: (context, index) {
            var appointment = controller.appointments[index];
            final status = appointment['status'] as String;

            return AppointmentCard(
              appointment: appointment,
              // The cancel button is only active if the appointment is pending or confirmed
              onCancel: (status == 'pending' || status == 'confirmed')
                  ? () => controller.cancelAppointment(appointment['id'], appointment['doctorId'])
                  : null,
              showQueueInfo: false, // Queue info is no longer relevant
            );
          },
        );
      }),
    );
  }
}