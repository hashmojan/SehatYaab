import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../view_model/controller/appointment_controller/doctor_controller/doctor_schedule_settings_controller.dart';

class DoctorScheduleSettingsPage extends StatelessWidget {
  DoctorScheduleSettingsPage({super.key});

  final ctrl = Get.put(DoctorScheduleSettingsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Settings')),
      body: Obx(() {
        if (ctrl.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Default Time Slots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ctrl.timeSlots.map((s) => Chip(
                  label: Text(s),
                  onDeleted: () => ctrl.removeSlot(s),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickRange(context),
                    child: const Text('Add Time Range'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: ctrl.save,
                    child: Obx(() => ctrl.saving.value
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Timezone (informational)', style: TextStyle(fontWeight: FontWeight.w600)),
              TextField(
                controller: TextEditingController(text: ctrl.timezone.value),
                onChanged: (v) => ctrl.timezone.value = v,
                decoration: const InputDecoration(hintText: 'e.g. Asia/Karachi, UTC'),
              )
            ],
          ),
        );
      }),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final start = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (start == null) return;
    final end = await showTimePicker(context: context, initialTime: TimeOfDay(hour: start.hour + 1, minute: start.minute));
    if (end == null) return;

    String fmt(TimeOfDay t) {
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final mm = t.minute.toString().padLeft(2, '0');
      final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$h:${mm} $ampm';
    }

    final slot = '${fmt(start)} - ${fmt(end)}';
    ctrl.addSlot(slot);
  }
}
