import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sehatyab/models/doctor/schedule_slot/schedule_slot.dart';

class AddEditScheduleDialog extends StatefulWidget {
  final String title;
  final ScheduleSlot? initialSlot;
  final Future<ScheduleSlot?> Function(ScheduleSlot) onSave;

  const AddEditScheduleDialog({
    Key? key,
    required this.title,
    this.initialSlot,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddEditScheduleDialogState createState() => _AddEditScheduleDialogState();
}

class _AddEditScheduleDialogState extends State<AddEditScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  late String _selectedDay;
  late String _startTime;
  late String _endTime;
  late bool _isAvailable;
  late int _maxAppointments;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialSlot?.day ?? daysOfWeek[0];
    _startTime = widget.initialSlot?.startTime ?? '09:00';
    _endTime = widget.initialSlot?.endTime ?? '17:00';
    _isAvailable = widget.initialSlot?.isAvailable ?? true;
    _maxAppointments = widget.initialSlot?.maxAppointments ?? 10;
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = TimeOfDay(
      hour: int.parse(isStartTime ? _startTime.split(':')[0] : _endTime.split(':')[0]),
      minute: int.parse(isStartTime ? _startTime.split(':')[1] : _endTime.split(':')[1]),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      final formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStartTime) {
          _startTime = formattedTime;
        } else {
          _endTime = formattedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDay,
                items: daysOfWeek.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_startTime),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_endTime),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available for Appointments'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _maxAppointments.toString(),
                decoration: const InputDecoration(
                  labelText: 'Max Appointments',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter maximum appointments';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _maxAppointments = int.parse(value!);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveForm,
          child: _isSaving
              ? const CircularProgressIndicator()
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSaving = true);

      final newSlot = ScheduleSlot(
        id: widget.initialSlot?.id ?? '',
        doctorId: widget.initialSlot?.doctorId ?? '',
        day: _selectedDay,
        startTime: _startTime,
        endTime: _endTime,
        date: widget.initialSlot?.date ?? DateTime.now(),
        isAvailable: _isAvailable,
        maxAppointments: _maxAppointments,
      );

      try {
        final result = await widget.onSave(newSlot);
        if (mounted) {
          Get.back(result: result);
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: ${e.toString()}')),
          );
        }
      }
    }
  }
}