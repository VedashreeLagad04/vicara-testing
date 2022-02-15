class ScreenArgs {
  late Map<String, dynamic>? screenArgs;
  ScreenArgs();
  ScreenArgs.fromMAP(Map<String, dynamic> data) {
    screenArgs = data;
  }
  Map<String, dynamic>? get getArgs => screenArgs;
}
