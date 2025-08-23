import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../models/doctor/schedule_slot/schedule_slot.dart';
import '../../../res/components/time_range_picker.dart';
import '../../../view_model/controller/appointment_controller/schedule_controller/doctor_schedule_provider.dart';

class DoctorSchedulePage extends StatefulWidget {
  const DoctorSchedulePage({super.key});

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize the provider
    Future.microtask(() =>
        Provider.of<DoctorScheduleProvider>(context, listen: false).fetchSchedule());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorScheduleProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Doctor Schedule'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[300],
            tabs: const [
              Tab(icon: Icon(Icons.schedule), text: 'My Schedule'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Weekly View'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.add),
              onSelected: (value) {
                if (value == 'single') {
                  _showAddSlotDialog(context);
                } else if (value == 'weekly') {
                  _showWeeklyScheduleDialog(context);
                }
              },
              itemBuilder: (BuildContext context) {
                return {'Single Day', 'Whole Week'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice.toLowerCase().replaceAll(' ', '_'),
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => Provider.of<DoctorScheduleProvider>(context, listen: false).fetchSchedule(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            ScheduleListView(),
            WeeklyScheduleView(),
          ],
        ),
      ),
    );
  }

  void _showAddSlotDialog(BuildContext context, {String? initialDay}) {
    final provider = Provider.of<DoctorScheduleProvider>(context, listen: false);
    final dayController = TextEditingController(text: initialDay ?? 'Monday');
    final maxAppointmentsController = TextEditingController(text: '10');
    bool isAvailable = true;
    TimeRange? selectedTimeRange;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Schedule Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: dayController.text,
                      items: provider.daysOfWeek.map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) => dayController.text = value!,
                      decoration: const InputDecoration(
                        labelText: 'Day',
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final timeRange = await showTimeRangePicker(
                          context: context,
                          start: const TimeOfDay(hour: 9, minute: 0),
                          end: const TimeOfDay(hour: 17, minute: 0),
                          interval: const Duration(minutes: 30),
                          minDuration: const Duration(hours: 1),
                          disabledTime: TimeRange(
                            start: const TimeOfDay(hour: 0, minute: 0),
                            end: const TimeOfDay(hour: 6, minute: 0),
                          ),
                        );
                        if (timeRange != null) {
                          setState(() => selectedTimeRange = timeRange);
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Time Range',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          controller: TextEditingController(
                            text: selectedTimeRange != null
                                ? '${selectedTimeRange!.start.format(context)} - ${selectedTimeRange!.end.format(context)}'
                                : 'Select time range',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: maxAppointmentsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Appointments Per Slot',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Available for appointments'),
                      value: isAvailable,
                      onChanged: (value) => setState(() => isAvailable = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedTimeRange == null) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Please select a time range')),
                      // );
                      return;
                    }

                    provider.addNewSlot(
                      day: dayController.text,
                      startTime: '${selectedTimeRange!.start.hour}:${selectedTimeRange!.start.minute}',
                      endTime: '${selectedTimeRange!.end.hour}:${selectedTimeRange!.end.minute}',
                      maxAppointments: int.tryParse(maxAppointmentsController.text) ?? 10,
                      isAvailable: isAvailable,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Add Slot'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditSlotDialog(BuildContext context, ScheduleSlot slot) {
    final provider = Provider.of<DoctorScheduleProvider>(context, listen: false);
    final dayController = TextEditingController(text: slot.day);
    final maxAppointmentsController = TextEditingController(text: slot.maxAppointments.toString());
    bool isAvailable = slot.isAvailable;

    // Parse existing time
    final startParts = slot.startTime.split(':');
    final endParts = slot.endTime.split(':');
    TimeRange? selectedTimeRange = TimeRange(
      start: TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1])),
      end: TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1])),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Schedule Slot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: dayController.text,
                      items: provider.daysOfWeek.map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) => dayController.text = value!,
                      decoration: const InputDecoration(
                        labelText: 'Day',
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final timeRange = await showTimeRangePicker(
                          context: context,
                          start: selectedTimeRange!.start,
                          end: selectedTimeRange!.end,
                          interval: const Duration(minutes: 30),
                          minDuration: const Duration(hours: 1),
                        );
                        if (timeRange != null) {
                          setState(() => selectedTimeRange = timeRange);
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Time Range',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          controller: TextEditingController(
                            text: selectedTimeRange != null
                                ? '${selectedTimeRange!.start.format(context)} - ${selectedTimeRange!.end.format(context)}'
                                : 'Select time range',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: maxAppointmentsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Appointments Per Slot',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Available for appointments'),
                      value: isAvailable,
                      onChanged: (value) => setState(() => isAvailable = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedTimeRange == null) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Please select a time range')),
                      // );
                      return;
                    }

                    provider.updateSlot(
                      id: slot.id,
                      day: dayController.text,
                      startTime: '${selectedTimeRange!.start.hour}:${selectedTimeRange!.start.minute}',
                      endTime: '${selectedTimeRange!.end.hour}:${selectedTimeRange!.end.minute}',
                      maxAppointments: int.tryParse(maxAppointmentsController.text) ?? 10,
                      isAvailable: isAvailable,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSlot(BuildContext context, ScheduleSlot slot) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete the schedule slot for ${slot.day} (${slot.startTime}-${slot.endTime})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Provider.of<DoctorScheduleProvider>(context, listen: false).deleteSlot(slot.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showWeeklyScheduleDialog(BuildContext context) {
    final provider = Provider.of<DoctorScheduleProvider>(context, listen: false);
    final maxAppointmentsController = TextEditingController(text: '10');
    final selectedDays = <String>[];
    TimeRange? selectedTimeRange;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Weekly Schedule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final timeRange = await showTimeRangePicker(
                          context: context,
                          start: const TimeOfDay(hour: 9, minute: 0),
                          end: const TimeOfDay(hour: 17, minute: 0),
                          interval: const Duration(minutes: 30),
                          minDuration: const Duration(hours: 1),
                        );
                        if (timeRange != null) {
                          setState(() => selectedTimeRange = timeRange);
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Time Range',
                            suffixIcon: Icon(Icons.access_time),
                          ),
                          controller: TextEditingController(
                            text: selectedTimeRange != null
                                ? '${selectedTimeRange!.start.format(context)} - ${selectedTimeRange!.end.format(context)}'
                                : 'Select time range',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: maxAppointmentsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Appointments Per Slot',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Days:'),
                    Wrap(
                      spacing: 8,
                      children: provider.daysOfWeek.map((day) {
                        return FilterChip(
                          label: Text(day),
                          selected: selectedDays.contains(day),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDays.isEmpty) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Please select at least one day')),
                      // );
                      return;
                    }
                    if (selectedTimeRange == null) {
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Please select a time range')),
                      // );
                      return;
                    }

                    provider.addWeeklySchedule(
                      days: selectedDays,
                      startTime: '${selectedTimeRange!.start.hour}:${selectedTimeRange!.start.minute}',
                      endTime: '${selectedTimeRange!.end.hour}:${selectedTimeRange!.end.minute}',
                      maxAppointments: int.tryParse(maxAppointmentsController.text) ?? 10,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Save Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


class ScheduleListView extends StatelessWidget {
  const ScheduleListView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorScheduleProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.scheduleSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Schedule Added',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showScheduleOptions(context),
              child: const Text('Add Schedule'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.scheduleSlots.length,
      itemBuilder: (context, index) {
        final slot = provider.scheduleSlots[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _buildAvailabilityIcon(slot),
            title: Text(
              '${slot.day}: ${_formatTimeDisplay(context, slot.startTime)} - ${_formatTimeDisplay(context, slot.endTime)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: _buildSlotSubtitle(slot),
            trailing: _buildActionButtons(context, slot),
            onTap: () => _DoctorSchedulePageState()._showEditSlotDialog(context, slot),
          ),
        );
      },
    );
  }

  String _formatTimeDisplay(BuildContext context, String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);
      return timeOfDay.format(context);
    } catch (e) {
      return time;
    }
  }

  Widget _buildAvailabilityIcon(ScheduleSlot slot) {
    return CircleAvatar(
      backgroundColor: slot.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
      radius: 15,
      child: Icon(
        slot.isAvailable ? Icons.check : Icons.close,
        size: 15,
        color: slot.isAvailable ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildSlotSubtitle(ScheduleSlot slot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Max Appointments: ${slot.maxAppointments}'),
        if (!slot.isAvailable)
          const Text(
            'Not accepting patients',
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ScheduleSlot slot) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _DoctorSchedulePageState()._showEditSlotDialog(context, slot),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _DoctorSchedulePageState()._confirmDeleteSlot(context, slot),
        ),
      ],
    );
  }

  void _showScheduleOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Add Single Day Schedule'),
              onTap: () {
                Navigator.pop(context);
                _DoctorSchedulePageState()._showAddSlotDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Add Weekly Schedule'),
              onTap: () {
                Navigator.pop(context);
                _DoctorSchedulePageState()._showWeeklyScheduleDialog(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class WeeklyScheduleView extends StatelessWidget {
  const WeeklyScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorScheduleProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildWeekNavigation(context),
        Expanded(
          child: ListView.builder(
            itemCount: 7,
            itemBuilder: (context, dayIndex) {
              final day = provider.daysOfWeek[dayIndex];
              final daySlots = provider.getSlotsForDay(day);
              return _buildDayScheduleCard(context, day, daySlots);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekNavigation(BuildContext context) {
    final provider = Provider.of<DoctorScheduleProvider>(context);
    final formatter = DateFormat('MMM d');

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: provider.previousWeek,
          ),
          Text(
            '${formatter.format(provider.currentWeekStart)} - '
                '${formatter.format(provider.currentWeekEnd)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: provider.nextWeek,
          ),
        ],
      ),
    );
  }

  Widget _buildDayScheduleCard(BuildContext context, String day, List<ScheduleSlot> daySlots) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _DoctorSchedulePageState()._showAddSlotDialog(context, initialDay: day),
                ),
              ],
            ),
            const Divider(),
            if (daySlots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No schedule for this day',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...daySlots.map((slot) => _buildWeeklySlotItem(context, slot)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySlotItem(BuildContext context, ScheduleSlot slot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          _buildAvailabilityIcon(slot),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_formatTimeDisplay(context, slot.startTime)} - ${_formatTimeDisplay(context, slot.endTime)}',
              style: TextStyle(
                color: slot.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _DoctorSchedulePageState()._showEditSlotDialog(context, slot),
          ),
        ],
      ),
    );
  }

  String _formatTimeDisplay(BuildContext context, String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);
      return timeOfDay.format(context);
    } catch (e) {
      return time;
    }
  }

  Widget _buildAvailabilityIcon(ScheduleSlot slot) {
    return CircleAvatar(
      backgroundColor: slot.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
      radius: 15,
      child: Icon(
        slot.isAvailable ? Icons.check : Icons.close,
        size: 15,
        color: slot.isAvailable ? Colors.green : Colors.red,
      ),
    );
  }
}