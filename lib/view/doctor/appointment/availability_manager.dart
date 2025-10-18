// views/doctor/availability_manager.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../models/doctor/appointment/availability_model.dart';
import '../../../view_model/controller/appointment_controller/doctor_controller/doctor_availability_controller.dart';

class AvailabilityManagerPage extends StatelessWidget {
  final DoctorDailyAvailabilityController _controller = Get.find<DoctorDailyAvailabilityController>();

  AvailabilityManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'select_dates') {
                _showSelectDatesDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'select_dates',
                child: Text('Select Available Days'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend for the calendar
          _buildLegend(),
          const SizedBox(height: 10),
          // Calendar section with Expanded to prevent overflow
          Expanded(
            child: Obx(() => _buildCalendar()),
          ),
          const SizedBox(height: 10),
          // Selected day status
          Obx(() => _buildSelectedDayStatus()),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final dailyAvailability = _controller.dailyAvailability.value;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _controller.focusedDay.value,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          return _controller.selectedDays.contains(normalizedDay);
        },
        onDaySelected: (selectedDay, focusedDay) {
          _controller.toggleSelectedDay(selectedDay);
          _controller.setFocusedDay(focusedDay);
        },
        onDayLongPressed: (date, focusedDay) {
          _showChangeAvailabilityDialog(Get.context!, date, dailyAvailability);
        },
        eventLoader: (day) {
          final dateKey = _formatDateKey(day);
          final dailyData = dailyAvailability[dateKey];
          if (dailyData?.status == 'unavailable') {
            return ['unavailable'];
          }
          if (dailyData != null && dailyData.isFull()) {
            return ['full'];
          }
          return [];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              final isFull = events.contains('full');
              final isUnavailable = events.contains('unavailable');
              return Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: isUnavailable ? Colors.red : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  width: 8.0,
                  height: 8.0,
                ),
              );
            }
            return null;
          },
          defaultBuilder: (context, day, focusedDay) {
            final dateKey = _formatDateKey(day);
            final dailyData = dailyAvailability[dateKey];
            if (dailyData?.status == 'available') {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    Text(
                      '${dailyData!.patientLimit}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, color: Colors.green, size: 12),
          SizedBox(width: 4),
          Text('Available', style: TextStyle(fontSize: 12)),
          SizedBox(width: 16),
          Icon(Icons.circle, color: Colors.orange, size: 12),
          SizedBox(width: 4),
          Text('Full', style: TextStyle(fontSize: 12)),
          SizedBox(width: 16),
          Icon(Icons.circle, color: Colors.red, size: 12),
          SizedBox(width: 4),
          Text('Unavailable', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSelectedDayStatus() {
    final selectedDay = _controller.selectedDay.value;
    final dailyAvailability = _controller.dailyAvailability.value;

    if (selectedDay == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Center(child: Text('Select a date to see details.')),
      );
    }

    final dateKey = _formatDateKey(selectedDay);
    final DailyAvailabilityModel? dailyData = dailyAvailability[dateKey];
    String statusText;

    if (dailyData == null) {
      statusText = 'No specific settings for this day. Default schedule applies.';
    } else {
      if (dailyData.status == 'unavailable') {
        statusText = 'Status: Unavailable';
      } else {
        statusText = 'Status: Available';
        if (dailyData.patientLimit > 0) {
          statusText += '\nPatient Limit: ${dailyData.patientLimit}';
          statusText += '\nAppointments Booked: ${dailyData.appointmentsCount}';
          statusText += '\nSlots Available: ${dailyData.patientLimit - dailyData.appointmentsCount}';
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Availability for ${DateFormat.yMMMd().format(selectedDay)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(statusText),
              if (dailyData != null && dailyData.status == 'available')
                ElevatedButton(
                  onPressed: () {
                    _showChangeAvailabilityDialog(Get.context!, selectedDay, dailyAvailability);
                  },
                  child: const Text('Edit Availability'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _showSelectDatesDialog(BuildContext context) {
    final DoctorDailyAvailabilityController controller = Get.find<DoctorDailyAvailabilityController>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Expanded(
          
          child: AlertDialog(
            title: const Text('Select Available Days'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select the days you want to be available:'),
                  const SizedBox(height: 16),
                  // Fixed: This Obx now properly observes selectedDays
                  Obx(() {
                    final selectedDays = controller.selectedDays;
                    final allDates = List.generate(
                        60, // Reduced from 365 to 60 days for better performance
                            (index) => DateTime.now().add(Duration(days: index))
                    );

                    return SizedBox(
                      height: 400, // Fixed height for scrollable content
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allDates.length,
                        itemBuilder: (BuildContext listContext, int index) {
                          final date = allDates[index];
                          final normalizedDate = DateTime(date.year, date.month, date.day);
                          final isCurrentlySelected = selectedDays.contains(normalizedDate);

                          return CheckboxListTile(
                            title: Text(DateFormat.yMMMd().format(date)),
                            value: isCurrentlySelected,
                            onChanged: (bool? value) {
                              controller.toggleSelectedDay(date);
                            },
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () {
                  if (controller.selectedDays.isNotEmpty) {
                    controller.setAvailableDays(controller.selectedDays.toList());
                  } else {
                    Get.snackbar('Warning', 'Please select at least one day');
                  }
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangeAvailabilityDialog(
      BuildContext context,
      DateTime date,
      Map<String, DailyAvailabilityModel> currentData
      ) {
    final dateKey = _formatDateKey(date);
    final DailyAvailabilityModel? initialData = currentData[dateKey];
    final RxString status = (initialData?.status ?? 'available').obs;
    final RxInt patientLimit = (initialData?.patientLimit ?? 20).obs;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Obx(() {
          return AlertDialog(
            title: Text('Change Availability for ${DateFormat.yMMMd().format(date)}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: status.value,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(
                      value: 'unavailable',
                      child: Text('Unavailable'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      status.value = newValue;
                    }
                  },
                ),
                const SizedBox(height: 10),
                if (status.value == 'available')
                  TextFormField(
                    initialValue: patientLimit.value.toString(),
                    decoration: const InputDecoration(labelText: 'Patient Limit'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      patientLimit.value = int.tryParse(value) ?? 20;
                    },
                  ),
                const SizedBox(height: 10),
                Text(
                  'Current Status: ${initialData?.status ?? 'Not Set'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (initialData != null) ...[
                  Text(
                    'Appointments Booked: ${initialData.appointmentsCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (initialData.status == 'available')
                    Text(
                      'Available Slots: ${initialData.patientLimit - initialData.appointmentsCount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () {
                  _controller.updateDailyAvailability(
                    date: date,
                    status: status.value,
                    patientLimit: patientLimit.value,
                  );
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }
}