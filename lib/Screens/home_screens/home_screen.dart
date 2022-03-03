import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:badges/badges.dart';
import 'package:vicara/Screens/Widgets/notification_widget.dart';
import 'package:vicara/Screens/Widgets/server_status_foreground.dart';
// import 'package:vicara/Screens/Widgets/server_status.dart';
import 'package:vicara/Services/auth/auth.dart';
import 'package:vicara/Services/consts.dart';
import 'package:vicara/Services/location_service.dart';
import 'package:vicara/Services/logout_popup.dart';
import 'package:vicara/Services/prefs.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

bool shouldRunForeground = true;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final Preferences _preferences = Preferences();
  final StreamController<bool> _locationConnectionStream = StreamController<bool>();
  final Auth _auth = Auth();
  bool internetAvailable = false;
  final StreamController<Map> _notifications = StreamController();

  @override
  void initState() {
    super.initState();
    _auth.authState.listen((user) {
      if (user == null) Navigator.pushReplacementNamed(context, auth);
    });
    _locationService.init().then((data) {
      _locationService.serviceEnabled.then((value) {
        _locationConnectionStream.add(value);
      });
    });

    Stream.periodic(const Duration(seconds: 5)).listen((ticker) async {
      _locationConnectionStream.add(await _locationService.serviceEnabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          popLogout(
              context: context,
              callback: () {
                _preferences.clear();
                _auth.signOut();
              },
              title: "Logout?",
              subTitle: "Do you want logout?");
          return true;
        } catch (e) {
          return false;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                              text: 'Welcome to ',
                              style: Provider.of<ThemeDataProvider>(context)
                                  .textTheme['dark-w400-s24']),
                          TextSpan(
                            text: 'Drive Safe',
                            style:
                                Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          width: 2.0, color: Provider.of<ThemeDataProvider>(context).orange),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined),
                              StreamBuilder<bool>(
                                stream: _locationConnectionStream.stream,
                                builder: (context, snapshot) {
                                  return snapshot.data == true
                                      ? Badge(
                                          badgeColor:
                                              Provider.of<ThemeDataProvider>(context).alertGreen,
                                          child: Text(
                                            'GPS Connected',
                                            style: Provider.of<ThemeDataProvider>(context)
                                                .textTheme['dark-w600-s10'],
                                          ),
                                        )
                                      : Badge(
                                          badgeColor:
                                              Provider.of<ThemeDataProvider>(context).alertRed,
                                          child: Text(
                                            'GPS disconnected',
                                            style: Provider.of<ThemeDataProvider>(context)
                                                .textTheme['dark-w600-s10'],
                                          ),
                                        );
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ServerStatus(notificationSink: _notifications.sink),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Provider.of<ThemeDataProvider>(context).black,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Stars Collected',
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w600-s16'],
                              ),
                              Text(
                                'You got 4 stars on your latest ride. Keep it up champ!',
                                style: Provider.of<ThemeDataProvider>(context)
                                    .textTheme['white-w400-s10'],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '450',
                              style: Provider.of<ThemeDataProvider>(context)
                                  .textTheme['white-w400-s48'],
                            ),
                            Icon(
                              Icons.star_rounded,
                              size: 48,
                              color: Provider.of<ThemeDataProvider>(context).orange,
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  NotificationWidget(notificationController: _notifications),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
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
                            'Additional Information',
                            style:
                                Provider.of<ThemeDataProvider>(context).textTheme['white-w600-s16'],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(emergencyInfo);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                width: double.maxFinite,
                                decoration: BoxDecoration(
                                    color: Provider.of<ThemeDataProvider>(context).white,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.medical_services),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        'Emergency Information',
                                        style: Provider.of<ThemeDataProvider>(context)
                                            .textTheme['dark-w600-s14'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                // Notification.();
                                Navigator.of(context).pushNamed(fallHistory);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                width: double.maxFinite,
                                decoration: BoxDecoration(
                                    color: Provider.of<ThemeDataProvider>(context).white,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(FontAwesomeIcons.carCrash),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        'Fall History',
                                        style: Provider.of<ThemeDataProvider>(context)
                                            .textTheme['dark-w600-s14'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
