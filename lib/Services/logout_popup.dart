import 'package:flutter/material.dart';
import 'package:vicara/Screens/Widgets/round_button.dart';

void popLogout({
  required BuildContext context,
  required Function() callback,
  required String title,
  required String subTitle,
}) async {
  bool option = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(subTitle),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text(
                  "No",
                  style: TextStyle(color: Colors.black),
                )),
            RoundButton(
                text: "Logout",
                onPressed: () async {
                  Navigator.of(context).pop(true);
                })
          ],
        );
      });
  if (option) {
    callback();
  }
}
