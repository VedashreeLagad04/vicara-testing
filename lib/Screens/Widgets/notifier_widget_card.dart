import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';
import 'package:vicara/Screens/Widgets/round_button.dart';

class NotifierWidgetCard extends StatelessWidget {
  const NotifierWidgetCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 2.0, color: Provider.of<ThemeDataProvider>(context).white),
        borderRadius: BorderRadius.circular(20),
        color: Provider.of<ThemeDataProvider>(context).white,
      ),
      child: Column(
        children: [
          Text(
            'Fall Detected',
            style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s24'],
          ),
          Text(
            'It looks like you have taken a fall',
            style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s12'],
          ),
          RoundButton(text: 'I\'m Okay', onPressed: () {})
        ],
      ),
    );
  }
}
