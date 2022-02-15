import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';

class RoundButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final Color color;
  final TextStyle? textStyle;
  const RoundButton(
      {Key? key,
      required this.text,
      required this.onPressed,
      this.textStyle,
      this.color = const Color(0xFFFC8019)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(color),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 37.0, vertical: 3),
        child: Text(
          text,
          style: textStyle ?? Provider.of<ThemeDataProvider>(context).textTheme['white-w400-s16'],
        ),
      ),
    );
  }
}
