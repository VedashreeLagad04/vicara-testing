import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vicara/Providers/theme_data.provider.dart';

class RoundButton extends StatefulWidget {
  final String text;
  final Function() onPressed;
  final Color color;
  final TextStyle? textStyle;
  final bool? shouldLoad;
  const RoundButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.textStyle,
    this.shouldLoad = true,
    this.color = const Color(0xFFFC8019),
  }) : super(key: key);

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(widget.color),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      onPressed: () async {
        if (widget.shouldLoad!) {
          if (!_isLoading) {
            setState(() {
              _isLoading = true;
            });
            await widget.onPressed();
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          widget.onPressed();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 37.0, vertical: 3),
        child: _isLoading
            ? const CircularProgressIndicator()
            : Text(
                widget.text,
                style: widget.textStyle ??
                    Provider.of<ThemeDataProvider>(context).textTheme['white-w400-s16'],
              ),
      ),
    );
  }
}
