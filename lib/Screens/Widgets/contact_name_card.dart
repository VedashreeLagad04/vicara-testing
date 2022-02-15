import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';

class ContactNameCard extends StatelessWidget {
  final String contactName, number;
  final bool isSelected;
  final Function() onTap;
  const ContactNameCard({
    Key? key,
    required this.contactName,
    required this.number,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Provider.of<ThemeDataProvider>(context).orange
                  : Provider.of<ThemeDataProvider>(context).white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
            ),
            width: double.maxFinite,
            height: 56.0,
            margin: const EdgeInsets.only(left: 28),
            child: Padding(
              padding: const EdgeInsets.only(left: 44.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contactName,
                    style: isSelected
                        ? Provider.of<ThemeDataProvider>(context).textTheme['white-w400-s16']
                        : Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s16'],
                  ),
                  Text(
                    number,
                    style: isSelected
                        ? Provider.of<ThemeDataProvider>(context).textTheme['white-w400-s12']
                        : Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s12'],
                  )
                ],
              ),
            ),
          ),
          CircleAvatar(
            radius: 28.0,
            backgroundColor: isSelected
                ? Provider.of<ThemeDataProvider>(context).white
                : Provider.of<ThemeDataProvider>(context).orange,
            foregroundColor: Provider.of<ThemeDataProvider>(context).white,
            child: Text(
              contactName.isEmpty ? ":D" : contactName[0],
              style: isSelected
                  ? Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s24']
                  : Provider.of<ThemeDataProvider>(context).textTheme['white-w400-s24'],
            ),
          ),
        ],
      ),
    );
  }
}
