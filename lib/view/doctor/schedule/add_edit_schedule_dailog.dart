import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../models/doctor/appointment/availability_model.dart';

class SetDailyAvailabilityDialog extends StatefulWidget {
  final DateTime date;
  final DailyAvailabilityModel? initialData;
  final void Function(String status, int patientLimit) onSave;

  const SetDailyAvailabilityDialog({
    Key? key,
    required this.date,
    this.initialData,
    required this.onSave,
  }) : super(key: key);

  @override
  _SetDailyAvailabilityDialogState createState() => _SetDailyAvailabilityDialogState();
}

class _SetDailyAvailabilityDialogState extends State<SetDailyAvailabilityDialog> {
  late final RxString _status;
  late final TextEditingController _patientLimitController;

  @override
  void initState() {
    super.initState();
    _status = (widget.initialData?.status ?? 'available').obs;
    _patientLimitController = TextEditingController(
      text: (widget.initialData?.patientLimit ?? 10).toString(),
    );
  }

  @override
  void dispose() {
    _patientLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set Availability for ${DateFormat.yMMMd().format(widget.date)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Obx(
                  () => Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Available'),
                      value: 'available',
                      groupValue: _status.value,
                      onChanged: (value) {
                        if (value != null) {
                          _status.value = value;
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Unavailable'),
                      value: 'unavailable',
                      groupValue: _status.value,
                      onChanged: (value) {
                        if (value != null) {
                          _status.value = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(
                  () => Visibility(
                visible: _status.value == 'available',
                child: TextField(
                  controller: _patientLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Limit for this Day',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 10',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final patientLimit = int.tryParse(_patientLimitController.text) ?? 0;
            if (_status.value == 'available' && patientLimit <= 0) {
              Get.snackbar('Error', 'Patient limit must be greater than 0');
              return;
            }
            widget.onSave(_status.value, patientLimit);
            Get.back();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}