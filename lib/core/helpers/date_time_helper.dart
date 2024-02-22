import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateRangeType {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
  allYear,
  custom
}

/// Utils all about date in Dart
class DateTimeHelper {
  DateTimeHelper._();

  // ########################### WEEK ############################
  /// Find the first date of the week which contains the provided date.
  static DateTime findFirstDateOfTheWeek(DateTime dateTime) {
    return dateTime.subtract(Duration(days: dateTime.weekday - 1)).toLocal();
  }

  /// Find last date of the week which contains provided date.
  static DateTime findLastDateOfTheWeek(DateTime dateTime) {
    return dateTime
        .add(Duration(days: DateTime.daysPerWeek - dateTime.weekday))
        .toLocal();
  }

  /// Find first date of previous week using a date in current week.
  /// [dateTime] A date in current week.
  static DateTime findFirstDateOfPreviousWeek(DateTime dateTime) {
    final sameWeekDayOfLastWeek = dateTime.subtract(const Duration(days: 7));
    return findFirstDateOfTheWeek(sameWeekDayOfLastWeek);
  }

  /// Find last date of previous week using a date in current week.
  /// [dateTime] A date in current week.
  static DateTime findLastDateOfPreviousWeek(DateTime dateTime) {
    final sameWeekDayOfLastWeek = dateTime.subtract(const Duration(days: 7));
    return findLastDateOfTheWeek(sameWeekDayOfLastWeek);
  }

  /// Find first date of next week using a date in current week.
  /// [dateTime] A date in current week.
  static DateTime findFirstDateOfNextWeek(DateTime dateTime) {
    final sameWeekDayOfNextWeek = dateTime.add(const Duration(days: 7));
    return findFirstDateOfTheWeek(sameWeekDayOfNextWeek);
  }

  /// Find last date of next week using a date in current week.
  /// [dateTime] A date in current week.
  static DateTime findLastDateOfNextWeek(DateTime dateTime) {
    final sameWeekDayOfNextWeek = dateTime.add(const Duration(days: 7));
    return findLastDateOfTheWeek(sameWeekDayOfNextWeek);
  }

  // ########################### MONTH ############################

  /// Find the first date of the month which contains the provided date.
  static DateTime findFirstDateOfTheMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month).toLocal();
  }

  /// Find last date of the month which contains provided date.
  static DateTime findLastDateOfTheMonth(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.getLastDay(),
    ).toLocal();
  }

  /// Find first date of Previous month using a date in current month.
  /// [dateTime] A date in current month.
  static DateTime findFirstDateOfPreviousMonth(DateTime dateTime) {
    return dateTime.prevMonth();
  }

  /// Find last date of Previous month using a date in current month.
  /// [dateTime] A date in current month.
  static DateTime findLastDateOfPreviousMonth(DateTime dateTime) {
    return dateTime.prevMonthLastDate();
  }

  /// Find first date of Next month using a date in current month.
  /// [dateTime] A date in current month.
  static DateTime findFirstDateOfNextMonth(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month + 1,
    ).toLocal();
  }

  /// Find last date of Next month using a date in current month.
  /// [dateTime] A date in current month.
  static DateTime findLastDateOfNextMonth(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      dateTime.month + 1,
      dateTime.getLastDay(),
    ).toLocal();
  }

  // ########################### YEAR ############################

  /// Find the first date of the year which contains the provided date.
  static DateTime findFirstDateOfTheYear(DateTime dateTime) {
    return DateTime(
      dateTime.year,
    ).toLocal();
  }

  /// Find last date of the year which contains provided date.
  static DateTime findLastDateOfTheYear(DateTime dateTime) {
    return DateTime(
      dateTime.year,
      12,
      31,
    ).toLocal();
  }

  // ###############################################################

  /// Find equal [DateTime] from [DateTime] `a` with [DateTime] `b`.
  /// Without equal `hour, minute, & second` ..
  static bool isEqualDateByDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Find equal [DateTime] from [DateTime] `a` with [DateTime] `b`.
  /// equal only in `year & month` ..
  static bool isEqualDateByMonth(DateTime a, DateTime b) {
    final _difference = b.difference(a).inDays + 1;

    return a.year == b.year &&
        a.month == b.month &&
        _difference == a.getLastDay();
  }

  /// Find equal [DateTime] from [DateTime] `a` with [DateTime] `b`.
  /// equal only in `year & month` ..
  static bool isEqualDateByYear(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == 1 &&
        a.day == 1 &&
        b.month == 12 &&
        b.day == 31;
  }

  static bool isThisDay(DateTime firstDay, DateTime lastDay) {
    return isEqualDateByDay(firstDay, DateTime.now()) &&
        isEqualDateByDay(lastDay, DateTime.now());
  }

  static bool isPreviousDay(DateTime firstDay, DateTime lastDay) {
    return isEqualDateByDay(
          firstDay,
          DateTime.now().subtract(
            const Duration(days: 1),
          ),
        ) &&
        isEqualDateByDay(
          lastDay,
          DateTime.now().subtract(
            const Duration(days: 1),
          ),
        );
  }

  /// Check date is past This Week
  static bool isThisWeek(DateTime startDay, DateTime endDay) {
    final startDayInWeek =
        findFirstDateOfTheWeek(minifyFormatDate(DateTime.now()));
    final endDayInWeek =
        findLastDateOfTheWeek(minifyFormatDate(DateTime.now()));

    final isStartWeek = isEqualDateByDay(startDayInWeek, startDay);
    final isEndWeek = isEqualDateByDay(endDayInWeek, endDay);

    if (isStartWeek && isEndWeek) {
      return true;
    }

    return false;
  }

  /// Check date is past last Week
  static bool isLastWeek(DateTime startDay, DateTime endDay) {
    final startDayInWeek =
        findFirstDateOfPreviousWeek(minifyFormatDate(DateTime.now()));
    final endDayInWeek =
        findLastDateOfPreviousWeek(minifyFormatDate(DateTime.now()));

    final isStartWeek = isEqualDateByDay(startDayInWeek, startDay);
    final isEndWeek = isEqualDateByDay(endDayInWeek, endDay);

    if (isStartWeek && isEndWeek) {
      return true;
    }

    return false;
  }

  /// Check date is past Previous Week
  static bool isPreviousWeek(DateTime startDay, DateTime endDay) {
    final startDayInWeek =
        findFirstDateOfPreviousWeek(minifyFormatDate(DateTime.now()));
    final endDayInWeek =
        findLastDateOfPreviousWeek(minifyFormatDate(DateTime.now()));

    final isStartWeek = isEqualDateByDay(startDayInWeek, startDay);
    final isEndWeek = isEqualDateByDay(endDayInWeek, endDay);

    if (isStartWeek && isEndWeek) {
      return true;
    }

    return false;
  }

  /// Check date is This Month
  static bool isThisMonth(DateTime startDay, DateTime endDay) {
    final startDayInMonth =
        findFirstDateOfTheMonth(minifyFormatDate(DateTime.now()));
    final endDayInMonth =
        findLastDateOfTheMonth(minifyFormatDate(DateTime.now()));

    final isStartMonth = isEqualDateByDay(startDayInMonth, startDay);
    final isEndMonth = isEqualDateByDay(endDayInMonth, endDay);

    if (isStartMonth && isEndMonth) {
      return true;
    }

    return false;
  }

  /// Check date is last Month
  static bool isLastMonth(DateTime startDay, DateTime endDay) {
    final startDayInMonth =
        findFirstDateOfPreviousMonth(minifyFormatDate(DateTime.now()));
    final endDayInMonth =
        findLastDateOfPreviousMonth(minifyFormatDate(DateTime.now()));

    final isStartMonth = isEqualDateByDay(startDayInMonth, startDay);
    final isEndMonth = isEqualDateByDay(endDayInMonth, endDay);

    if (isStartMonth && isEndMonth) {
      return true;
    }

    return false;
  }

  static bool isThisYear(DateTime startDay, DateTime endDay) {
    final firstDay = findFirstDateOfTheYear(DateTime.now());
    final lastDay = findLastDateOfTheYear(DateTime.now());

    if (isEqualDateByDay(startDay, firstDay) &&
        isEqualDateByDay(endDay, lastDay)) {
      return true;
    }
    return false;
  }

  static bool isLastYear(DateTime startDay, DateTime endDay) {
    final _firstDate = DateTime(
      DateTime.now().year - 1,
      1,
      DateTime(DateTime.now().year, 1 + 1, 0).day,
    );

    final _endDate = DateTime(
      DateTime.now().year - 1,
      12,
      DateTime(DateTime.now().year, 12 + 1, 0).day,
    );

    final isStartMonth = isEqualDateByDay(_firstDate, startDay);
    final isEndMonth = isEqualDateByDay(_endDate, endDay);

    if (isStartMonth && isEndMonth) {
      return true;
    }

    return false;
  }

  /// Minify date format to delete `hour`, `minute`, & `second`
  static DateTime minifyFormatDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateRangeType dateRangeToType(DateTime? startDay, DateTime? endDay) {
    if (startDay != null && endDay != null) {
      if (DateTimeHelper.isThisDay(startDay, endDay)) {
        return DateRangeType.today;
      } else if (DateTimeHelper.isPreviousDay(startDay, endDay)) {
        return DateRangeType.yesterday;
      } else if (DateTimeHelper.isThisWeek(startDay, endDay)) {
        return DateRangeType.thisWeek;
      } else if (DateTimeHelper.isLastWeek(startDay, endDay)) {
        return DateRangeType.lastWeek;
      } else if (DateTimeHelper.isThisMonth(startDay, endDay)) {
        return DateRangeType.thisMonth;
      } else if (DateTimeHelper.isLastMonth(startDay, endDay)) {
        return DateRangeType.lastMonth;
      } else if (DateTimeHelper.isThisYear(startDay, endDay)) {
        return DateRangeType.thisYear;
      } else if (DateTimeHelper.isLastYear(startDay, endDay)) {
        return DateRangeType.lastYear;
      }
      return DateRangeType.custom;
    } else {
      return DateRangeType.allYear;
    }
  }

  static String? getTextDateRange(
    BuildContext context, {
    required DateTime? startDay,
    required DateTime? endDay,
    String dateFormat = 'MMM d',
  }) {
    final type = dateRangeToType(startDay, endDay);

    switch (type) {
      case DateRangeType.today:
        return context.l10n.today;
      case DateRangeType.yesterday:
        return context.l10n.yesterday;
      case DateRangeType.thisWeek:
        return context.l10n.thisWeek;
      case DateRangeType.lastWeek:
        return context.l10n.lastWeek;
      case DateRangeType.thisMonth:
        return context.l10n.thisMonth;
      case DateRangeType.lastMonth:
        return context.l10n.lastMonth;
      case DateRangeType.thisYear:
        return context.l10n.thisYear;
      case DateRangeType.lastYear:
        return context.l10n.lastYear;
      case DateRangeType.allYear:
        return context.l10n.allYear;
      case DateRangeType.custom:
        if (isEqualDateByDay(startDay!, endDay!)) {
          return DateFormat(dateFormat).format(startDay);
        } else if (isEqualDateByMonth(startDay, endDay)) {
          return DateFormat('MMM yyyy').format(startDay);
        } else if (isEqualDateByYear(startDay, endDay)) {
          return DateFormat('yyyy').format(startDay);
        }
        return '${DateFormat(dateFormat).format(startDay)}'
            ' - ${DateFormat(dateFormat).format(endDay)}';

      // ignore: no_default_cases
      default:
        return null;
    }
  }
}

extension DateTimeX on DateTime {
  DateTime nextMonth() {
    return DateTime(
      year,
      month + 1,
    ).toLocal();
  }

  DateTime nextMonthLastDate() {
    return DateTime(year, month + 1, _calculateLastDay(month + 1)).toLocal();
  }

  DateTime prevMonth() {
    return DateTime(
      year,
      month - 1,
    ).toLocal();
  }

  DateTime prevMonthLastDate() {
    return DateTime(year, month - 1, _calculateLastDay(month - 1)).toLocal();
  }

  int getLastDay() {
    return _calculateLastDay(month);
  }

  int _calculateLastDay(int currentMonth) {
    final isKabisat = year % 4 == 0;

    final _dateInMonths = [
      31,
      if (isKabisat) 29 else 28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];

    return (currentMonth >= 1 && currentMonth <= 12)
        ? _dateInMonths[currentMonth - 1]
        : _dateInMonths.last;
  }

  DateTime nextYearFirstDate() {
    return DateTime(
      year + 1,
    ).toLocal();
  }

  DateTime nextYearLastDate() {
    return DateTime(year + 1, 12, 31).toLocal();
  }

  DateTime prevYearFirstDate() {
    return DateTime(
      year - 1,
    ).toLocal();
  }

  DateTime prevYearLastDate() {
    return DateTime(year - 1, 12, 31).toLocal();
  }
}
