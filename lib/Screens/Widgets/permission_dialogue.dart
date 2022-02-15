import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';

class PermissionDialogue extends StatelessWidget {
  final Function() onSubmit;
  final String title, subTitle;
  const PermissionDialogue({
    Key? key,
    required this.onSubmit,
    required this.title,
    required this.subTitle,
  }) : super(key: key);

  get child => null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w600-s16'],
      ),
      content: Text(
        title,
        style: Provider.of<ThemeDataProvider>(context).textTheme['dark-w500-s14'],
      ),
      actions: [TextButton(onPressed: onSubmit, child: const Text('OK'))],
    );
  }
}
