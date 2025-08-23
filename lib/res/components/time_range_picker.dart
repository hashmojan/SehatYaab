// components/time_range_picker.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<TimeRange?> showTimeRangePicker({  // Changed return type
  required BuildContext context,
  required TimeOfDay start,
  required TimeOfDay end,
  Duration interval = const Duration(minutes: 30),
  Duration? minDuration,
  TimeRange? disabledTime,
}) {
  return showDialog<TimeRange>(
    context: context,
    builder: (context) => TimeRangePickerDialog(
      initialStart: start,
      initialEnd: end,
      interval: interval,
      minDuration: minDuration,
      disabledTime: disabledTime,
    ),
  );
}
class TimeRangePickerDialog extends StatefulWidget {
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final Duration interval;
  final Duration? minDuration;
  final TimeRange? disabledTime;

  const TimeRangePickerDialog({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    this.interval = const Duration(minutes: 30),
    this.minDuration,
    this.disabledTime,
  });

  @override
  State<TimeRangePickerDialog> createState() => _TimeRangePickerDialogState();
}

class _TimeRangePickerDialogState extends State<TimeRangePickerDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isStartTimeSelected = true;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStart;
    _endTime = widget.initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Time Range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeButton(_startTime, true),
              const Icon(Icons.arrow_forward),
              _buildTimeButton(_endTime, false),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeRangeSelector(),
          const SizedBox(height: 16),
          Text(
            'Duration: ${_calculateDuration().inHours}h ${_calculateDuration().inMinutes.remainder(60)}m',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (widget.minDuration != null && _calculateDuration() < widget.minDuration!)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Minimum duration: ${widget.minDuration!.inHours}h ${widget.minDuration!.inMinutes.remainder(60)}m',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValidRange ? () => Navigator.pop(context, TimeRange(start: _startTime, end: _endTime)) : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _buildTimeButton(TimeOfDay time, bool isStart) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isStartTimeSelected == isStart ? Theme.of(context).primaryColor : null,
      ),
      onPressed: () => setState(() => _isStartTimeSelected = isStart),
      child: Text(
        time.format(context),
        style: TextStyle(
          color: _isStartTimeSelected == isStart ? Colors.white : null,
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: Theme.of(context).brightness,
        ),
        child: TimePicker(
          initialTime: _isStartTimeSelected ? _startTime : _endTime,
          interval: widget.interval.inMinutes,
          onTimeChanged: (time) {
            setState(() {
              if (_isStartTimeSelected) {
                _startTime = time;
                // Ensure end time is after start time
                if (!_isEndAfterStart(time, _endTime)) {
                  _endTime = TimeOfDay(
                    hour: time.hour + 1,
                    minute: time.minute,
                  );
                }
              } else {
                _endTime = time;
                // Ensure start time is before end time
                if (!_isEndAfterStart(_startTime, time)) {
                  _startTime = TimeOfDay(
                    hour: time.hour - 1,
                    minute: time.minute,
                  );
                }
              }
            });
          },
          disabledTime: widget.disabledTime,
        ),
      ),
    );
  }

  bool _isEndAfterStart(TimeOfDay start, TimeOfDay end) {
    return end.hour > start.hour || (end.hour == start.hour && end.minute > start.minute);
  }

  bool get _isValidRange {
    if (!_isEndAfterStart(_startTime, _endTime)) return false;
    if (widget.minDuration != null && _calculateDuration() < widget.minDuration!) return false;
    if (_isDisabledTime(_startTime) || _isDisabledTime(_endTime)) return false;
    return true;
  }

  bool _isDisabledTime(TimeOfDay time) {
    if (widget.disabledTime == null) return false;
    return time.hour >= widget.disabledTime!.start.hour &&
        time.hour < widget.disabledTime!.end.hour;
  }

  Duration _calculateDuration() {
    final now = DateTime.now();
    final startDateTime = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    final endDateTime = DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);
    return endDateTime.difference(startDateTime);
  }
}

class TimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final int interval;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final TimeRange? disabledTime;

  const TimePicker({
    super.key,
    required this.initialTime,
    required this.interval,
    required this.onTimeChanged,
    this.disabledTime,
  });

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late TimeOfDay _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.initialTime;
    _hourController = FixedExtentScrollController(initialItem: _currentTime.hour);
    _minuteController = FixedExtentScrollController(
      initialItem: _currentTime.minute ~/ widget.interval,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildHourPicker(),
        ),
        Expanded(
          child: _buildMinutePicker(),
        ),
      ],
    );
  }

  Widget _buildHourPicker() {
    return ListWheelScrollView.useDelegate(
      controller: _hourController,
      itemExtent: 50,
      perspective: 0.01,
      diameterRatio: 1.2,
      onSelectedItemChanged: (index) {
        _currentTime = _currentTime.replacing(hour: index);
        widget.onTimeChanged(_currentTime);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: 24,
        builder: (context, index) {
          final isDisabled = widget.disabledTime != null &&
              index >= widget.disabledTime!.start.hour &&
              index < widget.disabledTime!.end.hour;
          return Center(
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 24,
                color: isDisabled ? Colors.grey : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinutePicker() {
    final minuteOptions = List<int>.generate(
      60 ~/ widget.interval,
          (i) => i * widget.interval,
    );

    return ListWheelScrollView.useDelegate(
      controller: _minuteController,
      itemExtent: 50,
      perspective: 0.01,
      diameterRatio: 1.2,
      onSelectedItemChanged: (index) {
        _currentTime = _currentTime.replacing(minute: minuteOptions[index]);
        widget.onTimeChanged(_currentTime);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: minuteOptions.length,
        builder: (context, index) {
          final minute = minuteOptions[index];
          final isDisabled = widget.disabledTime != null &&
              _currentTime.hour >= widget.disabledTime!.start.hour &&
              _currentTime.hour < widget.disabledTime!.end.hour;
          return Center(
            child: Text(
              minute.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 24,
                color: isDisabled ? Colors.grey : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const TimeRange({required this.start, required this.end});
}