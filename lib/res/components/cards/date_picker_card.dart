import 'package:flutter/material.dart'as material;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';


import '../../colors/app_colors.dart';

class DatePickerCard extends StatelessWidget {
  final DateTime? selectedDate;
  final List<DateTime> availableDates;
  final Function(DateTime) onDateSelected;
  final bool showMonthNavigation;

  const DatePickerCard({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.availableDates,
    this.showMonthNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableDates.length,
        itemBuilder: (context, index) {
          final date = availableDates[index];
          final isSelected = selectedDate?.day == date.day;
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : material.Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected ? AppColors.primaryColor : material.Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                        color: isSelected ? material.Colors.white : material.Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                        fontSize: 24,
                        color: isSelected ? material.Colors.white : material.Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}