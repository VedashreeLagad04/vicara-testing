import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({Key? key}) : super(key: key);

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
              'We noticed you were driving really fast.',
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
                      'HSR Layout',
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
                      '12:41 PM',
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
                      '07/08/21',
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
