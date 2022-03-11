import 'dart:async';
import 'dart:isolate';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/fall_detection_screen/ambulance_screen.dart';
import 'package:vicara/Services/auth/auth.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:vicara/Services/fall_detection_foreground_service.dart';
// import 'package:vicara/Services/poc_foreground.dart';

import 'package:vicara/Services/notifier.dart';
import 'package:vicara/Services/prefs.dart';

class ServerStatus extends StatefulWidget {
  final StreamSink<Map<dynamic, dynamic>> notificationSink;
  const ServerStatus({required this.notificationSink, Key? key}) : super(key: key);

  @override
  _ServerStatusState createState() => _ServerStatusState();
}

class _ServerStatusState extends State<ServerStatus> {
  final StreamController<bool> _wssConnectionStatusStream = StreamController();
  final Preferences _preferences = Preferences();
  final Notifier _notifier = Notifier();
  final Auth _auth = Auth();

  Stream? _receivePort;

  Future<void> _initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'com.example.vicara',
        channelName: 'Foreground Notification for vicara fall detection',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'false_alert', text: 'False alert'),
          const NotificationButton(id: 'exit', text: 'exit'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 100,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
      printDevLog: true,
    );
  }

  Future<bool> _startForegroundTask() async {
    String phone = await _preferences.getString('phone_no');
    await FlutterForegroundTask.saveData(key: 'phone', value: phone);

    ReceivePort? receivePort;
    if (await FlutterForegroundTask.isRunningService) {
      receivePort = await FlutterForegroundTask.restartService();
    } else {
      receivePort = await FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    if (receivePort != null) {
      _receivePort = receivePort.asBroadcastStream();
      _receivePort?.listen((message) async {
        if (message['type'] == 'ws-connection-status') {
          _wssConnectionStatusStream.sink.add(message['data']);
          // print('data${message['data']}');
        }
        if (message['type'] == 'event') {
          // _wssConnectionStatusStream.sink.add(message['data']);
          if (message['data']['type'] == "Fall") {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    AmbulanceScreen(lat: message['data']['lat'], long: message['data']['long']),
              ),
            );
            _notifier.show(
              'event detected ' + message['data']['name'],
              'Notified',
              'fall_in_foreground',
            );
          }
          var date = DateTime.fromMillisecondsSinceEpoch(message['data']['timestamp'] * 1000);
          widget.notificationSink.add({
            'type': message['data']['type'],
            'place': message['data']['place'],
            'time':
                "${(date.hour < 10 ? '0${date.hour}' : date.hour)}:${(date.minute < 10 ? '0${date.minute}' : date.minute)}",
            'date': "${date.year}-${date.month}-${date.day}"
          });
        }
      });

      return true;
    }

    return false;
  }

  Future<bool> _stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  @override
  void initState() {
    _initForegroundTask().then((value) {
      _startForegroundTask();
    });
    super.initState();
  }

  @override
  void dispose() {
    _wssConnectionStatusStream.close();
    if (_auth.currentUser == null) {
      _stopForegroundTask();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Row(
        children: [
          const Icon(Icons.dns_outlined),
          StreamBuilder<bool>(
              stream: _wssConnectionStatusStream.stream,
              initialData: false,
              builder: (context, snapshot) {
                return Badge(
                  badgeColor: snapshot.data == true
                      ? Provider.of<ThemeDataProvider>(context).alertGreen
                      : Provider.of<ThemeDataProvider>(context).alertRed,
                  child: Text(
                    snapshot.data == true ? 'Server Connected' : 'Server Disconnected',
                    style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s10'],
                  ),
                );
              }),
        ],
      ),
    );
  }
}
