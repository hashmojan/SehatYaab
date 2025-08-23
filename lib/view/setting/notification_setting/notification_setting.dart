import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../res/colors/app_colors.dart';

class NotificationSettingsController extends GetxController {
  final RxBool matchUpdates = true.obs;
  final RxBool chatNotifications = true.obs;
  final RxBool scoreAlerts = true.obs;

  @override
  void onInit() {
    _loadSettings();
    super.onInit();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    matchUpdates.value = prefs.getBool('notif_match') ?? true;
    chatNotifications.value = prefs.getBool('notif_chat') ?? true;
    scoreAlerts.value = prefs.getBool('notif_score') ?? true;
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

class NotificationSettingsPage extends GetView<NotificationSettingsController> {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationSwitch(
            'Match Updates',
            'Receive notifications for match events',
            controller.matchUpdates,
                (v) => controller._saveSetting('notif_match', v),
          ),
          _buildNotificationSwitch(
            'Chat Messages',
            'Get notified about new chat messages',
            controller.chatNotifications,
                (v) => controller._saveSetting('notif_chat', v),
          ),
          _buildNotificationSwitch(
            'Score Alerts',
            'Important score change notifications',
            controller.scoreAlerts,
                (v) => controller._saveSetting('notif_score', v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch(
      String title,
      String subtitle,
      RxBool value,
      Function(bool) onChanged,
      ) {
    return Obx(() => SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value.value,
      onChanged: (v) {
        value.value = v;
        onChanged(v);
      },
      activeColor: AppColors.primaryColor,
    ));
  }
}