import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/notification_card.dart';
import 'package:vicara/Screens/feature_screen/notifications_screen.dart';
import 'package:vicara/Services/APIs/notification_and_fall_history_apis.dart';

class NotificationWidget extends StatefulWidget {
  final StreamController<Map> notificationController;
  const NotificationWidget({required this.notificationController, Key? key}) : super(key: key);

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  var _freshNotification = [];
  final NotificationAndFallHistory _notificationAndFallHistory = NotificationAndFallHistory();

  @override
  void initState() {
    _notificationAndFallHistory.getNotifications().then((value) {
      if (value.isNotEmpty) {
        if (value.length > 1) {
          _freshNotification = value.sublist(1);
        }
        widget.notificationController.sink.add(value[0]);
      }
    }).catchError((onError) {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Provider.of<ThemeDataProvider>(context).orange,
      ),
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Text(
              'Notifications',
              style: Provider.of<ThemeDataProvider>(context).textTheme['white-w600-s16'],
            ),
          ),
          StreamBuilder<dynamic>(
            stream: widget.notificationController.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.active) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              } else {
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          "Something went wrong while loading notifications",
                          textAlign: TextAlign.center,
                          style: Provider.of<ThemeDataProvider>(context)
                              .textTheme['white-w600-s16']
                              ?.copyWith(
                                color: Provider.of<ThemeDataProvider>(context).alertRed,
                              ),
                        ),
                      ),
                    ),
                  );
                } else {
                  if (snapshot.data == null || snapshot.data.length == 0) {
                    return Center(
                      child: Text("Nothing to show here!:(",
                          style:
                              Provider.of<ThemeDataProvider>(context).textTheme['white-w600-s16']),
                    );
                  } else {
                    _freshNotification.insert(0, snapshot.data);
                    if (_freshNotification.length > 3) {
                      _freshNotification = _freshNotification.sublist(0, 3);
                    }

                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ..._freshNotification
                              .map<NotificationCard>(
                                (element) => NotificationCard(
                                  event: element['type'] ?? 'UNKNOWN',
                                  time: element['time'].length < 5
                                      ? element['time']
                                      : element['time'].substring(0, 5) ?? 'UNKNOWN',
                                  date: element['date'] ?? 'UNKNOWN',
                                  place: element['place'] != null
                                      ? element['place'].split('/')[0]
                                      : 'Nearby',
                                ),
                              )
                              .toList(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const NotificationsScreen()));
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Click to know more',
                                    style: Provider.of<ThemeDataProvider>(context)
                                        .textTheme['white-w600-s14'],
                                  ),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Provider.of<ThemeDataProvider>(context).white,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ]);
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
