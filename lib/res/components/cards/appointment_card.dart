import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../routes/routes_name.dart';
// Your Appointment model must be imported here to use the toMap() method
import '../../../models/doctor/appointment/appointment_model.dart';

class AppointmentCard extends StatelessWidget {
  // Use a dynamic type for the constructor to accept either a Map or an Appointment model
  final dynamic appointment;
  final bool isDoctorView;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onReschedule;
  final VoidCallback? onTap;
  final bool showStatusIndicator;
  final bool compactMode;
  final Color? cardColor;
  final bool showQueueInfo;
  final Widget? actions; // 🌟 Add this new optional parameter 🌟

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isDoctorView = false,
    this.onCancel,
    this.onConfirm,
    this.onReschedule,
    this.onTap,
    this.showStatusIndicator = true,
    this.compactMode = false,
    this.cardColor,
    this.showQueueInfo = false,
    this.actions, // 🌟 Initialize the new parameter 🌟
  });

  @override
  Widget build(BuildContext context) {
    // This is the core fix: Safely convert the input to a Map
    final Map<String, dynamic> appointmentData;
    if (appointment is Appointment) {
      // This line now works because the Appointment model has a toMap() method.
      appointmentData = (appointment as Appointment).toMap();
    } else if (appointment is Map<String, dynamic>) {
      appointmentData = appointment;
    } else {
      // Handle the case where the input is neither
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final status = appointmentData['status']?.toLowerCase() ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Card(
      color: cardColor ?? theme.cardTheme.color,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? () => _navigateToDetails(context, appointmentData),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: compactMode
              ? const EdgeInsets.all(12)
              : const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(theme, appointmentData),
              const SizedBox(height: 12),
              _buildDateTimeSection(theme, appointmentData),
              if (showQueueInfo) _buildQueueInfo(appointmentData),
              if (!compactMode && appointmentData['notes'] != null && appointmentData['notes'].isNotEmpty)
                _buildNotesSection(appointmentData),
              const SizedBox(height: 12),
              _buildFooterSection(theme, status, statusColor, appointmentData),
              if (actions != null) const SizedBox(height: 8), // Add a small space above the buttons
              if (actions != null) actions!, // 🌟 Render the new actions widget 🌟
            ],
          ),
        ),
      ),
    );
  }

  // All helper methods now take the Map as an argument
  Widget _buildHeaderSection(ThemeData theme, Map<String, dynamic> data) {
    return Row(
      children: [
        if (showStatusIndicator) _buildStatusIndicator(data),
        CircleAvatar(
          radius: compactMode ? 16 : 24,
          backgroundImage: _getProfileImage(data),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // FIXED: Show patient name when in doctor view, doctor name when in patient view
                isDoctorView
                    ? data['patientName'] ?? 'Patient Name Not Available'
                    : data['doctorName'] ?? 'Doctor Name Not Available',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: compactMode ? 14 : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!compactMode) Text(
                // FIXED: Show patient info when in doctor view, doctor specialty when in patient view
                isDoctorView
                    ? data['patientAge'] != null
                    ? 'Age: ${data['patientAge']}'
                    : (data['patientEmail'] ?? 'Patient')
                    : data['doctorSpecialty'] ?? 'Specialist',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: compactMode ? 12 : null,
                ),
              ),
            ],
          ),
        ),
        if (!compactMode)
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.dividerColor,
          ),
      ],
    );
  }

  ImageProvider _getProfileImage(Map<String, dynamic> data) {
    if (isDoctorView) {
      // FIXED: Use patient image in doctor view
      return data['patientImage'] != null && data['patientImage'].isNotEmpty
          ? NetworkImage(data['patientImage']!)
          : const AssetImage('assets/default_patient.png') as ImageProvider;
    } else {
      // Use doctor image in patient view
      return data['doctorImage'] != null && data['doctorImage'].isNotEmpty
          ? NetworkImage(data['doctorImage']!)
          : const AssetImage('assets/default_doctor.png') as ImageProvider;
    }
  }

  Widget _buildStatusIndicator(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getStatusColor(data['status'] ?? 'pending'),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDateTimeSection(ThemeData theme, Map<String, dynamic> data) {
    final date = _getAppointmentDate(data['date']);

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: compactMode ? 16 : 18,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 8),
        Text(
          date != null
              ? DateFormat('MMM dd, yyyy').format(date)
              : 'Date not available',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: compactMode ? 13 : null,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.access_time,
          size: compactMode ? 16 : 18,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 8),
        Text(
          data['timeSlot'] ?? 'Time not specified',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: compactMode ? 13 : null,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        if (data['location']?.isNotEmpty ?? false) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.location_on_outlined,
            size: compactMode ? 14 : 16,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 4),
          Text(
            data['location'],
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildQueueInfo(Map<String, dynamic> data) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Token: ${data['tokenNumber'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.people, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Queue: ${data['queuePosition'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        Text(
          'Patient Notes:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data['notes'],
          style: TextStyle(
            color: Colors.grey[700],
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFooterSection(ThemeData theme, String status, Color statusColor, Map<String, dynamic> data) {
    return Row(
      children: [
        _buildStatusChip(status, statusColor, theme),
        const Spacer(),
        if (onReschedule != null && _isEditable(status))
          _buildActionButton(
            label: 'Reschedule',
            icon: Icons.schedule,
            onPressed: onReschedule,
            theme: theme,
          ),
        if (onCancel != null && _isEditable(status))
          _buildActionButton(
            label: 'Cancel',
            icon: Icons.cancel_outlined,
            onPressed: onCancel,
            theme: theme,
          ),
        if (onConfirm != null && status == 'pending' && isDoctorView)
          _buildActionButton(
            label: 'Confirm',
            icon: Icons.check_circle_outline,
            onPressed: onConfirm,
            theme: theme,
          ),
      ],
    );
  }

  bool _isEditable(String status) {
    return status == 'pending' || status == 'confirmed';
  }

  Widget _buildStatusChip(String status, Color color, ThemeData theme) {
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 0.5,
          color: color,
        ),
      ),
      backgroundColor: color.withOpacity(0.2),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: theme.textTheme.labelSmall,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'rejected': return Colors.red;
      case 'completed': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  DateTime? _getAppointmentDate(dynamic dateField) {
    if (dateField is DateTime) {
      return dateField;
    } else if (dateField is Timestamp) {
      return dateField.toDate();
    }
    return null;
  }

  void _navigateToDetails(BuildContext context, Map<String, dynamic> data) {
    if (compactMode) return;
    Get.toNamed(RouteName.appointmentDetails, arguments: data);
  }
}