import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sehatyab/res/colors/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../models/doctor/appointment/availability_model.dart';
import '../../../view_model/controller/appointment_controller/doctor_controller/doctor_availability_controller.dart';

class AvailabilityManagerPage extends StatelessWidget {
  AvailabilityManagerPage({super.key});

  final DoctorDailyAvailabilityController _c =
  Get.isRegistered<DoctorDailyAvailabilityController>()
      ? Get.find<DoctorDailyAvailabilityController>()
      : Get.put(DoctorDailyAvailabilityController());

  static String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  List<String> _defaultSlots() => const [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
    '04:00 PM - 05:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        backgroundColor: AppColors.secondaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Select multiple days',
            icon: const Icon(Icons.event_available),
            onPressed: () => _showSelectDatesDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLegend(),
          const SizedBox(height: 10),
          Expanded(child: Obx(() => _buildCalendar())),
          const SizedBox(height: 10),
          Obx(() => _buildSelectedDayStatus()),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final map = _c.dailyAvailability;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _c.focusedDay.value,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (d) =>
            _c.selectedDays.contains(DateTime(d.year, d.month, d.day)),
        onDaySelected: (d, f) {
          _c.toggleSelectedDay(d);
          _c.setFocusedDay(f);
        },
        onDayLongPressed: (d, f) {
          final dayKey = _dateKey(d);
          final existing = map[dayKey];
          _showEditDialog(Get.context!, d, existing);
        },
        eventLoader: (d) {
          final key = _dateKey(d);
          final dd = map[key];
          if (dd == null) return [];
          if (dd.status == 'unavailable') return ['unavailable'];
          if (dd.isFull()) return ['full'];
          return ['available'];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            final hasFull = events.contains('full');
            final isUnavailable = events.contains('unavailable');
            return Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isUnavailable
                      ? Colors.red
                      : hasFull
                      ? Colors.orange
                      : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        children: const [
          _LegendDot(color: Colors.green, label: 'Available'),
          _LegendDot(color: Colors.orange, label: 'Full'),
          _LegendDot(color: Colors.red, label: 'Unavailable'),
        ],
      ),
    );
  }

  Widget _buildSelectedDayStatus() {
    final d = _c.selectedDay.value;
    final map = _c.dailyAvailability;
    if (d == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Select a date to view/edit.'),
      );
    }
    final key = _dateKey(d);
    final data = map[key];
    String text;
    if (data == null) {
      text = 'Not configured. Long-press the day to configure.';
    } else if (data.status == 'unavailable') {
      text = 'Unavailable';
    } else {
      final slots = data.timeSlots?.length ?? 0;
      final cap = slots > 0 ? slots : data.patientLimit;
      text =
      'Available • Capacity: $cap • Booked: ${data.appointmentsCount} • Remaining: ${cap - data.appointmentsCount}';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(
                'Availability for ${DateFormat.yMMMd().format(d)}\n$text',
              ),
            ),
            TextButton(
              onPressed: () {
                final existing = map[key];
                _showEditDialog(Get.context!, d, existing);
              },
              child: const Text('Edit'),
            ),
          ]),
        ),
      ),
    );
  }

  void _showSelectDatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        final days = List.generate(
            60, (i) => DateTime.now().add(Duration(days: i))); // 60-day view
        return AlertDialog(
          title: const Text('Select Available Days'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Obx(() {
              final selected = _c.selectedDays;
              return ListView.builder(
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final d = days[i];
                  final nd = DateTime(d.year, d.month, d.day);
                  final isOn = selected.contains(nd);
                  return CheckboxListTile(
                    title: Text(DateFormat.yMMMd().format(d)),
                    value: isOn,
                    onChanged: (_) => _c.toggleSelectedDay(d),
                  );
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _c.setAvailableDays(_c.selectedDays.toList());
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(
      BuildContext context, DateTime date, DailyAvailabilityModel? initial) {
    final status = (initial?.status ?? 'available').obs;
    final patientLimit = (initial?.patientLimit ?? 20).obs;

    // slots to toggle
    final allSlots = _defaultSlots();
    final selected = <String>{...?(initial?.timeSlots ?? <String>[])}.obs;

    showDialog(
      context: context,
      builder: (_) => Obx(() {
        final isAvailable = status.value == 'available';
        return AlertDialog(
          title: Text('Edit • ${DateFormat.yMMMd().format(date)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: status.value,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'available', child: Text('Available')),
                    DropdownMenuItem(value: 'unavailable', child: Text('Unavailable')),
                  ],
                  onChanged: (v) => status.value = v ?? 'available',
                ),
                const SizedBox(height: 12),
                if (isAvailable) ...[
                  TextFormField(
                    initialValue: patientLimit.value.toString(),
                    decoration:
                    const InputDecoration(labelText: 'Patient Limit (optional if using slots)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => patientLimit.value = int.tryParse(v) ?? 20,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Time Slots (optional — overrides capacity)',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 220,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: allSlots.length,
                      itemBuilder: (_, i) {
                        final slot = allSlots[i];
                        final on = selected.contains(slot);
                        return CheckboxListTile(
                          dense: true,
                          value: on,
                          title: Text(slot),
                          onChanged: (v) {
                            if (v == true) {
                              selected.add(slot);
                            } else {
                              selected.remove(slot);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                await _c.updateDailyAvailability(
                  date: date,
                  status: status.value,
                  patientLimit: patientLimit.value,
                  timeSlots: selected.isEmpty ? null : selected.toList(),
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
