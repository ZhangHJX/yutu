/// 秒 => hh:mm:ss
String secondsToDate(int seconds, {bool showDay = false}) {
  if (seconds < 0) {
    return '00:00:00';
  }

  final days = seconds ~/ 86400;
  final hours = (seconds % 86400) ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  if (showDay) {
    return '${days.toString().padLeft(2, '0')}天'
        '${hours.toString().padLeft(2, '0')}时'
        '${minutes.toString().padLeft(2, '0')}分'
        '${secs.toString().padLeft(2, '0')}秒';
  } else {
    return Duration(seconds: seconds).toString().split('.').first.padLeft(8, '0');
  }
}
