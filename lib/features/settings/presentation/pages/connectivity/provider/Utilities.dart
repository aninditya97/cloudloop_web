//utility  API
/*
 * @brief defines utilities API
 */
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

int convertMilisecondsFromTimeDateFormat(String yyyyMmDdHhMmSs) {
  /*
    String ConnectedTimeString = '20' + year.toString()
        + '/' + month.toString()
        + '/' + day.toString()
        + ' ' + hour.toString()
        + ':' + minute.toString()
        + ':00';
     */
  final dateTime = DateTime.parse(yyyyMmDdHhMmSs); // 문자열을 DateTime으로 변환
  final timeInMilliseconds =
      dateTime.millisecondsSinceEpoch; // DateTime을 밀리 초로 변환
  return timeInMilliseconds;
}

int CvtMiliSecsFromTimeDateFormat(String yyyyMmDdHhMmSs) {
  /*
    String ConnectedTimeString = '20' + year.toString()
        + '/' + month.toString()
        + '/' + day.toString()
        + ' ' + hour.toString()
        + ':' + minute.toString()
        + ':00';
     */
  final dateTime = DateTime.parse(yyyyMmDdHhMmSs); // 문자열을 DateTime으로 변환
  final timeInMilliseconds =
      dateTime.millisecondsSinceEpoch; // DateTime을 밀리 초로 변환
  return timeInMilliseconds;
}

String CvtMiliSecsToTimeDateFormat(int TimeMiliSecs) {
  final timeInMilliseconds = TimeMiliSecs;
  final dateTime = DateTime.fromMillisecondsSinceEpoch(timeInMilliseconds);
  final ConnectedTimeString =
      '${dateTime.year}/${addLeadingZero(dateTime.month)}/${addLeadingZero(dateTime.day)} ${addLeadingZero(dateTime.hour)}:${addLeadingZero(dateTime.minute)}:${addLeadingZero(dateTime.second)}';
  //  print(formattedDate); // 출력: "2023/04/29 16:17:17"
  return ConnectedTimeString;
}

int timeToMilliseconds(int hour, int minute, int second) {
  // 현재 날짜 정보를 가져옵니다.
  final now = DateTime.now();
  // 시간 정보(hour, minute, second)를 설정한 DateTime 객체를 생성합니다.
  final time = DateTime(now.year, now.month, now.day, hour, minute, second);
  // DateTime 객체에서 밀리 초 값을 가져와 반환합니다.
  return time.millisecondsSinceEpoch;
}

String millisecondsToTime(int milliseconds, {bool showLeadingZero = true}) {
  // 밀리 초 값을 DateTime 객체로 변환합니다.
  final time = DateTime.fromMillisecondsSinceEpoch(milliseconds);

  // DateTime 객체에서 시간 정보(hour, minute, second)를 추출합니다.
  final hour = time.hour;
  final minute = time.minute;
  final second = time.second;

  // 시간 정보를 문자열로 변환합니다.
  final hourStr = addLeadingZeroOption(hour, showLeadingZero);
  final minuteStr = addLeadingZeroOption(minute, showLeadingZero);
  final secondStr = addLeadingZeroOption(second, showLeadingZero);

  // 변환된 시간 정보를 출력합니다.
  final result = '$hourStr:$minuteStr:$secondStr';
  return result;
}

/**
 * @brief calculate difference between initTime and currentTime
 */
Duration calculateTimeDifference(int millis1, int millis2) {
  int difference = (millis1 - millis2).abs();
  return Duration(milliseconds: difference);
}

String formatDuration(Duration duration) {
  int days = duration.inDays;
  int hours = duration.inHours % 24;
  int minutes = duration.inMinutes % 60;
  int seconds = duration.inSeconds % 60;

  String result = '';
  if (days > 0) {
    result += '${days}d ';
  }
  else
  {
    result += '0d ';
  }

  if (hours > 0) {
    result += '${hours}h ';
  }
  else {
    result += '00h ';
  }

  if (minutes > 0) {
    result += '${minutes}mins ';
  }
  else {
    result += '00mins ';
  }
    // result += '${seconds}s';

    return result;
}

String formatDurationEx(BuildContext context, Duration duration)
{
  int days = duration.inDays;
  int hours = duration.inHours % 24;
  int minutes = duration.inMinutes % 60;
  int seconds = duration.inSeconds % 60;

  String result = '';
  if (days > 0) {
    result += '${days}${context.l10n.day} ';
  }
  else
  {
    result += '0${context.l10n.day} ';
  }

  if (hours > 0) {
    result += '${hours}${context.l10n.hour} ';
  }
  else {
    result += '00${context.l10n.hour} ';
  }

  if (minutes > 0) {
    result += '${minutes}${context.l10n.mins} ';
  }
  else {
    result += '00${context.l10n.mins} ';
  }
  // result += '${seconds}s';

  return result;
}


/**
 * @brief cgm transmitter expire time since insertion
 */
String formatDurationEx2(BuildContext context, Duration duration, int day, int hour, int min, int sec)
{
  int days = duration.inDays;
  int hours = duration.inHours % 24;
  int minutes = duration.inMinutes % 60;
  int seconds = duration.inSeconds % 60;

  if(day > 0)
  {
    days = days + day;
  }

  if(hour > 0)
  {
    hours = hours + hour;
  }

  if(min > 0)
  {
    minutes = minutes + min;
  }

  if(sec > 0)
  {
    seconds = seconds + sec;
  }

  String result = '';
  if (days > 0) {
    result += '${days}${context.l10n.day} ';
  }
  else
  {
    result += '0${context.l10n.day} ';
  }

  if (hours > 0) {
    result += '${hours}${context.l10n.hour} ';
  }
  else {
    result += '00${context.l10n.hour} ';
  }

  if (minutes > 0) {
    result += '${minutes}${context.l10n.mins} ';
  }
  else {
    result += '00${context.l10n.mins} ';
  }
  // result += '${seconds}s';

  return result;
}
// 자릿수를 맞추기 위해 숫자 앞에 0을 추가하는 함수입니다.
String addLeadingZeroOption(int number, bool showLeadingZero) {
  if (showLeadingZero) {
    return number.toString().padLeft(2, '0');
  } else {
    return number.toString();
  }
}

String addLeadingZero(int value) {
  return value.toString().padLeft(2, '0');
}

/*
 * @brief convert byte to hex
 */
String toHexString(int byte) {
  return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
}
