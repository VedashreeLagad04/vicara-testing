import 'package:flutter/material.dart';
import 'package:vicara/Services/consts.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);
  static String id = loading;
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ),
        ),
      ),
    );
  }
}
