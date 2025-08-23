// views/doctor/availability_manager.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Assuming this is your custom time range picker
import '../../../res/components/time_range_picker.dart';
import '../../../view_model/controller/appointment_controller/doctor_controller/doctor_availability_controller.dart';

class AvailabilityManagerPage extends StatelessWidget {
  final DoctorAvailabilityController _controller =
  Get.put(DoctorAvailabilityController());

  AvailabilityManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showDateExceptions(context), // Pass context
            tooltip: 'Manage Date Exceptions',
          ),
        ],
      ),
      body: Obx(
            () => _controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // General Settings
            _buildGeneralSettings(context), // Pass context
            const Divider(),
            // Date Exceptions
            Expanded(child: _buildDateExceptionList(context)), // Pass context and use Expanded
            const Divider(),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General Availability Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildWorkingDaysSelector(),
          const SizedBox(height: 16),
          _buildWorkingHoursPicker(context), // Pass context
          const SizedBox(height: 16),
          _buildBreakTimePicker(context), // Pass context
          const SizedBox(height: 16),
          _buildAppointmentDuration(),
        ],
      ),
    );
  }

  Widget _buildWorkingDaysSelector() {
    // Days are 1-7 for Monday-Sunday from DateTime.weekday
    final List<String> weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final List<int> weekdayValues = [1, 2, 3, 4, 5, 6, 7];

    return Obx(() {
      final currentWorkingDays = (_controller.availability['generalSettings']?['workingDays'] as List?)?.cast<int>() ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Working Days:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: List.generate(7, (index) {
              final dayValue = weekdayValues[index];
              final isSelected = currentWorkingDays.contains(dayValue);
              return FilterChip(
                label: Text(weekdays[index]),
                selected: isSelected,
                onSelected: (selected) {
                  List<int> updatedDays = List.from(currentWorkingDays);
                  if (selected) {
                    if (!updatedDays.contains(dayValue)) {
                      updatedDays.add(dayValue);
                    }
                  } else {
                    updatedDays.remove(dayValue);
                  }
                  _controller.updateWorkingDays(updatedDays);
                },
                selectedColor: Theme.of(Get.context!).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(Get.context!).primaryColor,
              );
            }),
          ),
        ],
      );
    });
  }

  Widget _buildWorkingHoursPicker(BuildContext context) {
    return Obx(() {
      final currentWorkingHours = _controller.availability['generalSettings']?['workingHours'];
      final String startTime = currentWorkingHours?['start'] ?? '09:00';
      final String endTime = currentWorkingHours?['end'] ?? '17:00';

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Working Hours:', style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () async {
              final TimeOfDay? pickedStartTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.parse(startTime.split(':')[0]),
                  minute: int.parse(startTime.split(':')[1]),
                ),
              );
              if (pickedStartTime != null) {
                final TimeOfDay? pickedEndTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(endTime.split(':')[0]),
                    minute: int.parse(endTime.split(':')[1]),
                  ),
                );
                if (pickedEndTime != null) {
                  _controller.updateWorkingHours(
                    _formatTimeOfDay(pickedStartTime),
                    _formatTimeOfDay(pickedEndTime),
                  );
                }
              }
            },
            child: Text('$startTime - $endTime'),
          ),
        ],
      );
    });
  }

  Widget _buildBreakTimePicker(BuildContext context) {
    return Obx(() {
      final currentBreakTime = _controller.availability['generalSettings']?['breakTime'];
      final String startTime = currentBreakTime?['start'] ?? '12:00';
      final String endTime = currentBreakTime?['end'] ?? '13:00';

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Break Time:', style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () async {
              final TimeOfDay? pickedStartTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.parse(startTime.split(':')[0]),
                  minute: int.parse(startTime.split(':')[1]),
                ),
              );
              if (pickedStartTime != null) {
                final TimeOfDay? pickedEndTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(endTime.split(':')[0]),
                    minute: int.parse(endTime.split(':')[1]),
                  ),
                );
                if (pickedEndTime != null) {
                  _controller.updateBreakTime(
                    _formatTimeOfDay(pickedStartTime),
                    _formatTimeOfDay(pickedEndTime),
                  );
                }
              }
            },
            child: Text('$startTime - $endTime'),
          ),
        ],
      );
    });
  }

  Widget _buildAppointmentDuration() {
    return Obx(() {
      final int currentDuration = (_controller.availability['generalSettings']?['appointmentDuration'] as int?) ?? 30;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Appointment Duration:', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<int>(
            value: currentDuration,
            items: const [
              DropdownMenuItem(value: 15, child: Text('15 mins')),
              DropdownMenuItem(value: 30, child: Text('30 mins')),
              DropdownMenuItem(value: 45, child: Text('45 mins')),
              DropdownMenuItem(value: 60, child: Text('60 mins')),
            ],
            onChanged: (value) {
              if (value != null) {
                _controller.updateAppointmentDuration(value);
              }
            },
          ),
        ],
      );
    });
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() => ElevatedButton.icon(
        icon: _controller.isSaving.value
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Icon(Icons.save),
        label: Text(_controller.isSaving.value ? 'Saving...' : 'Save Availability'),
        onPressed: _controller.isSaving.value ? null : _controller.saveAvailability,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Theme.of(Get.context!).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      )),
    );
  }

  void _showDateExceptions(BuildContext context) { // Accept context
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Manage Date Exceptions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            // Use Expanded for the ListView.builder to allow it to take available space
            Expanded(
              child: _buildDateExceptionList(context),
            ),
            _buildAddExceptionButton(context), // Pass context
          ],
        ),
      ),
      isScrollControlled: true, // Allow bottom sheet to be scrollable if content overflows
    );
  }

  Widget _buildDateExceptionList(BuildContext context) {
    return Obx(() {
      final exceptions = _controller.availability['exceptions'] as List<dynamic>? ?? [];
      if (exceptions.isEmpty) {
        return const Center(child: Text('No exceptions added yet.'));
      }
      return ListView.builder(
        shrinkWrap: true, // This is okay when wrapped by Expanded/SizedBox
        itemCount: exceptions.length,
        itemBuilder: (context, index) {
          final exception = exceptions[index];
          final dateStr = exception['date'] as String;
          final isAvailable = exception['isAvailable'] as bool;
          final customSlots = (exception['customSlots'] as List?)?.cast<String>() ?? [];

          return ListTile(
            title: Text(DateFormat.yMMMd().format(DateTime.parse(dateStr))),
            subtitle: Text(isAvailable
                ? (customSlots.isEmpty ? 'Available (No custom slots)' : 'Available: ${_formatSlots(customSlots)}')
                : 'Unavailable'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _controller.removeExceptionDate(DateTime.parse(dateStr)),
            ),
            onTap: () => _editExceptionDate(context, DateTime.parse(dateStr), isAvailable, customSlots), // Pass context
          );
        },
      );
    });
  }

  Widget _buildAddExceptionButton(BuildContext context) { // Accept context
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add Exception Date'),
        onPressed: () async {
          final DateTime? picked = await showDatePicker(
            context: context, // Use the provided context
            initialDate: DateTime.now().add(const Duration(days: 1)), // Start from tomorrow
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // Two years from now
          );
          if (picked != null) {
            // Show dialog to choose availability for the exception
            _showAddExceptionOptionsDialog(context, picked);
          }
        },
      ),
    );
  }

  void _showAddExceptionOptionsDialog(BuildContext context, DateTime date) {
    final RxBool isAvailable = false.obs;
    final RxList<String> customSlots = <String>[].obs;
    final DateFormat timeFormat = DateFormat('HH:mm');

    Get.defaultDialog(
      title: 'Exception for ${DateFormat.yMMMd().format(date)}',
      content: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Available on this date'),
            trailing: Switch(
              value: isAvailable.value,
              onChanged: (val) {
                isAvailable.value = val;
                if (!val) customSlots.clear(); // Clear custom slots if not available
              },
            ),
          ),
          if (isAvailable.value)
            Column(
              children: [
                const Text('Custom Slots (Optional):'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: customSlots.map((slot) => Chip(
                    label: Text(slot),
                    onDeleted: () => customSlots.remove(slot),
                  )).toList(),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom Slot'),
                  onPressed: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      final String newSlot = timeFormat.format(DateTime(2000,1,1, pickedTime.hour, pickedTime.minute));
                      if (!customSlots.contains(newSlot)) {
                        customSlots.add(newSlot);
                      }
                    }
                  },
                ),
              ],
            ),
        ],
      )),
      confirm: ElevatedButton(
        onPressed: () {
          _controller.addExceptionDate(
            date,
            isAvailable: isAvailable.value,
            customSlots: isAvailable.value ? customSlots.toList() : null,
          );
          Get.back(); // Close dialog
        },
        child: const Text('Add Exception'),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }

  void _editExceptionDate(BuildContext context, DateTime date, bool currentIsAvailable, List<String> currentCustomSlots) {
    final RxBool isAvailable = currentIsAvailable.obs;
    final RxList<String> customSlots = currentCustomSlots.obs;
    final DateFormat timeFormat = DateFormat('HH:mm');

    Get.defaultDialog(
      title: 'Edit Exception for ${DateFormat.yMMMd().format(date)}',
      content: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Available on this date'),
            trailing: Switch(
              value: isAvailable.value,
              onChanged: (val) {
                isAvailable.value = val;
                if (!val) customSlots.clear();
              },
            ),
          ),
          if (isAvailable.value)
            Column(
              children: [
                const Text('Custom Slots (Optional):'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: customSlots.map((slot) => Chip(
                    label: Text(slot),
                    onDeleted: () => customSlots.remove(slot),
                  )).toList(),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom Slot'),
                  onPressed: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      final String newSlot = timeFormat.format(DateTime(2000,1,1, pickedTime.hour, pickedTime.minute));
                      if (!customSlots.contains(newSlot)) {
                        customSlots.add(newSlot);
                      }
                    }
                  },
                ),
              ],
            ),
        ],
      )),
      confirm: ElevatedButton(
        onPressed: () {
          // Remove old exception and add new one
          _controller.removeExceptionDate(date);
          _controller.addExceptionDate(
            date,
            isAvailable: isAvailable.value,
            customSlots: isAvailable.value ? customSlots.toList() : null,
          );
          Get.back(); // Close dialog
        },
        child: const Text('Update Exception'),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  String _formatSlots(List<String> slots) {
    if (slots.isEmpty) return '';
    return slots.map((slot) {
      // Assuming slot is in 'HH:mm' format
      final components = slot.split(':');
      final hour = int.parse(components[0]);
      final minute = int.parse(components[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      return '$displayHour:$minute $period';
    }).join(', ');
  }
}