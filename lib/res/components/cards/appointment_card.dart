import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sehatyab/res/routes/routes_name.dart';
import 'package:get/get.dart';

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final bool isDoctorView;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onReschedule;
  final VoidCallback? onTap;
  final bool showStatusIndicator;
  final bool compactMode;
  final Color? cardColor;
  final bool showQueueInfo;

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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = appointment['status']?.toLowerCase() ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Card(
      color: cardColor ?? theme.cardTheme.color,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? () => _navigateToDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: compactMode
              ? const EdgeInsets.all(12)
              : const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(theme),
              const SizedBox(height: 12),
              _buildDateTimeSection(theme),
              if (showQueueInfo) _buildQueueInfo(),
              if (!compactMode && appointment['notes'] != null && appointment['notes'].isNotEmpty)
                _buildNotesSection(),
              const SizedBox(height: 12),
              _buildFooterSection(theme, status, statusColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Row(
      children: [
        if (showStatusIndicator) _buildStatusIndicator(),
        CircleAvatar(
          radius: compactMode ? 16 : 24,
          backgroundImage: _getProfileImage(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDoctorView
                    ? appointment['patientName'] ?? 'Patient'
                    : appointment['doctorName'] ?? 'Doctor',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: compactMode ? 14 : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!compactMode) Text(
                isDoctorView
                    ? appointment['patientAge'] != null
                    ? 'Age: ${appointment['patientAge']}'
                    : ''
                    : appointment['doctorSpecialty'] ?? 'Specialist',
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

  ImageProvider _getProfileImage() {
    if (isDoctorView) {
      return appointment['patientImage'] != null
          ? NetworkImage(appointment['patientImage']!)
          : const AssetImage('assets/default_patient.png') as ImageProvider;
    } else {
      return appointment['doctorImage'] != null
          ? NetworkImage(appointment['doctorImage']!)
          : const AssetImage('assets/default_doctor.png') as ImageProvider;
    }
  }

  Widget _buildStatusIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getStatusColor(appointment['status'] ?? 'pending'),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDateTimeSection(ThemeData theme) {
    final date = _getAppointmentDate(appointment['date']);

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
          appointment['time'] ?? 'Time not specified',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: compactMode ? 13 : null,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        if (appointment['location']?.isNotEmpty ?? false) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.location_on_outlined,
            size: compactMode ? 14 : 16,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 4),
          Text(
            appointment['location'],
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildQueueInfo() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Token: ${appointment['tokenNumber'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.people, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Queue: ${appointment['queuePosition'] ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
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
          appointment['notes'],
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

  Widget _buildFooterSection(ThemeData theme, String status, Color statusColor) {
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
      case 'completed': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  DateTime? _getAppointmentDate(dynamic dateField) {
    if (dateField is DateTime) {
      return dateField;
    } else if (dateField is String) {
      return DateTime.tryParse(dateField);
    }
    return null;
  }

  void _navigateToDetails(BuildContext context) {
    if (compactMode) return;
    Get.toNamed(RouteName.appointmentDetails, arguments: appointment);
  }
}