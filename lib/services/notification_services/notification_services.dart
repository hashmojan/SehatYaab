// services/notification_services/notification_services.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'get_server_key.dart'; // Import your GetServerKey class

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Make GetServerKey an instance variable if it holds state,
  // or instantiate it inside methods if it's stateless.
  // For static methods, instantiating inside the method is often simplest.

  static Future<void> initialize() async {
    // Initialize settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        // You might want to navigate or perform an action based on response.payload
        print('Notification tapped with payload: ${response.payload}');
      },
    );

    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    } else {
      print('User did not grant permission for notifications');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_showNotification);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get and store FCM token
    await _storeFCMToken();
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Be sure to initialize Firebase here if you're not already doing it in main
    // await Firebase.initializeApp(); // Uncomment if needed for background messages
    print("Handling a background message: ${message.messageId}");
    await _showNotification(message);
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    // Create a unique ID for each notification if you want to update/cancel them later
    final id = DateTime.now().millisecondsSinceEpoch % 100000; // Simple unique ID

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'appointment_channel', // Channel ID
      'Appointment Notifications', // Channel name
      channelDescription: 'Notifications related to doctor appointments', // Channel description
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(), // Pass data as payload
    );
  }

  static Future<void> _storeFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token == null) {
      print('FCM token is null.');
      return;
    }

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('User not logged in, cannot store FCM token.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'fcmToken': token}, SetOptions(merge: true));
      print('FCM token stored for user $userId: $token');
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  // General method to send any notification
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final GetServerKey getServerKey = GetServerKey(); // Instantiate here
      final accessToken = await getServerKey.getServerKeyToken();

      if (accessToken == null) {
        print('Failed to get server key token. Cannot send notification.');
        return;
      }

      // Get user's FCM token from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) {
        print('FCM token not found for user: $userId. Notification not sent via FCM.');
        // Still show local notification even if FCM fails
        await _showNotification(RemoteMessage(
          notification: RemoteNotification(
            title: title,
            body: body,
          ),
          data: data,
        ));
        return;
      }

      // Define the FCM v1 API endpoint (replace 'weather-d82d9' with your actual project ID)
      const String projectId = 'weather-d82d9'; // Make sure this is your Firebase Project ID
      final String fcmUrl = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // Create the notification payload
      final Map<String, dynamic> message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            ...data,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      // Send the notification
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      // Check the response
      if (response.statusCode == 200) {
        print('Notification sent successfully to $userId');
      } else {
        print('Failed to send notification to $userId: ${response.statusCode} - ${response.body}');
      }

      // Also show local notification regardless of FCM success/failure
      await _showNotification(RemoteMessage(
        notification: RemoteNotification(
          title: title,
          body: body,
        ),
        data: data,
      ));
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Specific method for sending appointment-related notifications
  static Future<void> sendAppointmentNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    await sendNotification(userId: userId, title: title, body: body, data: data);
  }
}

