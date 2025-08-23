import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../res/colors/app_colors.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  // Static notification data
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Appointment Confirmed',
      message: 'Your appointment with Dr. Ali Khan has been confirmed for tomorrow at 2:00 PM',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      type: NotificationType.appointment,
    ),
    NotificationItem(
      id: '2',
      title: 'Reminder',
      message: 'Don\'t forget to take your medication at 8:00 AM',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      type: NotificationType.reminder,
    ),
    NotificationItem(
      id: '3',
      title: 'New Message',
      message: 'You have a new message from Dr. Sarah Ahmed regarding your test results',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.message,
    ),
    NotificationItem(
      id: '4',
      title: 'System Update',
      message: 'New features available in your sehatyab app. Update now!',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: NotificationType.system,
    ),
    NotificationItem(
      id: '5',
      title: 'Appointment Reminder',
      message: 'You have an appointment with Dr. Usman Malik in 1 hour',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: false,
      type: NotificationType.appointment,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.secondaryColor,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _markAllAsRead(),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _notifications.length,
        itemBuilder: (context, index) => _buildNotificationCard(_notifications[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your notifications will appear here',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.isRead ? Colors.white : Colors.blue[50],
      elevation: 0,
      child: ListTile(
        leading: _getNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: notification.isRead ? Colors.black : Colors.blue[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.timestamp),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : const Icon(Icons.circle, size: 10, color: Colors.blue),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return const Icon(Icons.calendar_today, color: Colors.blue);
      case NotificationType.reminder:
        return const Icon(Icons.notifications, color: Colors.orange);
      case NotificationType.message:
        return const Icon(Icons.message, color: Colors.green);
      case NotificationType.system:
        return const Icon(Icons.system_update, color: Colors.purple);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Handle notification tap based on type
    switch (notification.type) {
      case NotificationType.appointment:
        Get.snackbar(
          notification.title,
          'Opening appointment details...',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
      case NotificationType.reminder:
        Get.snackbar(
          notification.title,
          'Opening medication reminder...',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
      case NotificationType.message:
        Get.snackbar(
          notification.title,
          'Opening messages...',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
      case NotificationType.system:
        Get.snackbar(
          notification.title,
          'Opening system update...',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
    }

    // Mark as read when tapped
    _markAsRead(notification.id);
  }

  void _markAsRead(String id) {
    // In a real app, you would update this in your state management
    Get.snackbar(
      'Marked as read',
      'Notification has been marked as read',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _markAllAsRead() {
    Get.snackbar(
      'All marked as read',
      'All notifications have been marked as read',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

enum NotificationType {
  appointment,
  reminder,
  message,
  system,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });
}