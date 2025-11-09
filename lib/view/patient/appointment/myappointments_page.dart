import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../res/components/cards/appointment_card.dart';
import '../../../view_model/controller/appointment_controller/patient_controller/myappointments_controller.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            final appointment = controller.appointments[index];
            final status = (appointment['status'] as String?) ?? '';

            return AppointmentCard(
              appointment: appointment,
              onCancel: (status == 'pending' || status == 'confirmed')
                  ? () => controller.cancelAppointment(
                appointment['id'] as String,
                appointment['doctorId'] as String,
              )
                  : null,
              showQueueInfo: false,
            );
          },
        );
      }),
    );
  }
}
