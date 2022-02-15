import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Notifier {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings initializationSettingsAndroid =
      const AndroidInitializationSettings('ic_launcher');
  final IOSInitializationSettings initializationSettingsIOS =
      // ignore: prefer_const_constructors
      IOSInitializationSettings(
          onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) {
    Fluttertoast.showToast(
      msg: 'Notification sent. payload = $payload',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 5,
      backgroundColor: const Color(0x4F464646),
      textColor: Colors.black,
      fontSize: 16.0,
    );
  });
  late InitializationSettings initializationSettings;
  Notifier() {
    initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  }
  late NotificationDetails platformChannelSpecifics;
  void load(Function(String?)? onSelectNotification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'com.example.vicara', 'Vicara',
        channelDescription: 'Vicara fall detection system',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');
    const IOSNotificationDetails iosSpecific =
        IOSNotificationDetails(threadIdentifier: 'Vicara app');
    platformChannelSpecifics =
        const NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iosSpecific);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  show(String title, String subtitle, String payload) async => await flutterLocalNotificationsPlugin
      .show(0, title, subtitle, platformChannelSpecifics, payload: payload);
}
