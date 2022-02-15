import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';

class NotificationCard extends StatelessWidget {
  final String event;
  final String place;
  final String time;
  final String date;
  const NotificationCard(
      {required this.event, required this.place, required this.time, required this.date, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        width: double.maxFinite,
        decoration: BoxDecoration(
            color: Provider.of<ThemeDataProvider>(context).white,
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detected event $event',
              style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w500-s12'],
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                    ),
                    Text(
                      place,
                      style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s10'],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.query_builder,
                      size: 15,
                    ),
                    Text(
                      time,
                      style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s10'],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 15,
                    ),
                    Text(
                      date,
                      style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s10'],
                    ),
                  ],
                ),
              ),
            ]),
            Row(
              children: [
                Text(
                  'Click to know more',
                  style: Provider.of<ThemeDataProvider>(context).textTheme['orange-w600-s8'],
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 8,
                  color: Provider.of<ThemeDataProvider>(context).orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
