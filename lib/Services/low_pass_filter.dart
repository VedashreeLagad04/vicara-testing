class LowPassFilter {
  DateTime? startTime;
  int timeConstant;
  int count = 0;
  List output = [0.0];

  LowPassFilter(this.timeConstant, dataLength) {
    output = List.filled(dataLength, 0.0);
  }

  List filter(List input) {
    startTime ??= DateTime.now();

    if (output[0].isNaN) {
      output = List.filled(output.length, 0.0);
    }

    var timeDiff = DateTime.now().difference(startTime!).inMicroseconds;

    final dt = 1 / (count++ / (timeDiff / 1000000));
    final alpha = timeConstant / (timeConstant + dt);

    for (var i = 0; i < input.length; ++i) {
      output[i] = alpha * output[i] + ((1 - alpha) * input[i]);
    }

    return output;
  }
}
