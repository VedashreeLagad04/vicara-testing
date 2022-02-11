import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';

class FallHistoryCard extends StatelessWidget {
  const FallHistoryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 32),
      width: double.maxFinite,
      decoration: BoxDecoration(
          color: Provider.of<ThemeDataProvider>(context).black,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3:39 PM',
            style: Provider.of<ThemeDataProvider>(context).textTheme['white-w600-s14'],
          ),
          Text(
            '10 July 2021',
            style: Provider.of<ThemeDataProvider>(context).textTheme['white-w600-s14'],
          ),
          Text(
            'Silkboard Flyover, Bengaluru, Karnataka',
            style: Provider.of<ThemeDataProvider>(context).textTheme['white-w500-s14'],
          ),
        ],
      ),
    );
  }
}
