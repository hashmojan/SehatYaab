// import 'dart:typed_data';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart'; // Import Material for navigation
// import '../../view/notification_screen/notification_screen.dart'; // Import your NotificationsScreen
//
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
// FlutterLocalNotificationsPlugin();
//
// // Global navigator key to access the context
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
// void initializeNotifications() async {
//   const AndroidInitializationSettings initializationSettingsAndroid =
//   AndroidInitializationSettings('@mipmap/ic_launcher'); // Use your app's launcher icon
//
//   const InitializationSettings initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//   );
//
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) async {
//       // Handle notification click
//       if (response.payload == 'notifications') {
//         // Use the navigator key to access the context
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(
//             builder: (context) => NotificationsScreen(),
//           ),
//         );
//       }
//     },
//   );
// }
//
// void createNotificationChannel() async {
//   AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'weather_app_channel_id', // Channel ID
//     'Weather App Notifications', // Channel Name
//     importance: Importance.max,
//     playSound: true,
//     sound: const RawResourceAndroidNotificationSound('notification_sound'), // Optional: Custom sound
//     enableVibration: true,
//     vibrationPattern: Int64List.fromList([0, 500, 1000, 500]), // Optional: Custom vibration pattern
//   );
//
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);
// }