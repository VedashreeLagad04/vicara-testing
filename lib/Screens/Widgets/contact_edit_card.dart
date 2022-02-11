import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';

class ContactEditCard extends StatelessWidget {
  final String contactName, number;
  final Function() onTap;
  final IconData? icon;
  const ContactEditCard(
      {Key? key, required this.contactName, required this.number, required this.onTap, this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Provider.of<ThemeDataProvider>(context).white,
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
                  style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s16'],
                ),
                Text(
                  number,
                  style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w400-s12'],
                )
              ],
            ),
          ),
        ),
        CircleAvatar(
          radius: 28.0,
          backgroundColor: Provider.of<ThemeDataProvider>(context).orange,
          foregroundColor: Provider.of<ThemeDataProvider>(context).white,
          child: Text(
            contactName[0],
            style: Provider.of<ThemeDataProvider>(context).textTheme['white-w400-s24'],
          ),
        ),
        Positioned(
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(
                icon ?? Icons.edit_outlined,
                size: 16,
              ),
              onPressed: onTap,
            ),
          ),
        ),
      ],
    );
  }
}
