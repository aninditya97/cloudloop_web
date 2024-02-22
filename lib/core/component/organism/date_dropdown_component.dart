import 'package:cloudloop_mobile/core/component/molecule/input/custom_dropdown_button.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/helpers/date_time_helper.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef DateDropdownCallback = Function(DateTimeRange, String);

class DateDropdownComponent extends StatelessWidget {
  const DateDropdownComponent({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final DateTimeRange value;
  final DateDropdownCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => _pickDateRangePicker(context),
          child: Container(
            width: Dimens.dp32,
            height: Dimens.dp32,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.blueGray[200]!,
              ),
              borderRadius: BorderRadius.circular(
                Dimens.small,
              ),
            ),
            child: const Icon(
              Icons.calendar_today,
              size: Dimens.dp18,
              color: AppColors.primaryTextColor,
            ),
          ),
        ),
        const SizedBox(
          width: Dimens.dp8,
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            height: Dimens.dp32,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.blueGray[200]!,
              ),
              borderRadius: BorderRadius.circular(Dimens.small),
            ),
            child: CustomDropdownButton<DateTimeRange>(
              underline: const SizedBox(),
              elevation: 0,
              hint: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.dp16,
                ),
                child: HeadingText4(
                  text: _getStringValue(context, value),
                ),
              ),
              items: _getDateRangeOptions().map(
                (item) {
                  return DropdownMenuItem(
                    alignment: Alignment.centerLeft,
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.appPadding,
                      ),
                      child: HeadingText4(
                        text: _getStringValue(
                          context,
                          item,
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
              onChanged: (newValue) {
                onChanged(
                  newValue,
                  _getStringValue(
                    context,
                    newValue,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future _pickDateRangePicker(BuildContext context) async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 30),
      lastDate: DateTime.now(),
    );

    if (result is DateTimeRange) {
      onChanged(
        DateTimeRange(
          start: DateTimeHelper.minifyFormatDate(result.start),
          end: DateTimeHelper.minifyFormatDate(result.end),
        ),
        _getStringValue(context, result),
      );
    }
  }

  List<DateTimeRange> _getDateRangeOptions() {
    final _dateOptions = <DateTimeRange>[];

    final now = DateTimeHelper.minifyFormatDate(
      DateTime.now(),
    );
    _dateOptions
      ..add(
        DateTimeRange(
          start: now,
          end: now,
        ),
      )
      ..add(
        DateTimeRange(
          start: now.subtract(
            const Duration(
              days: 1,
            ),
          ),
          end: now.subtract(
            const Duration(
              days: 1,
            ),
          ),
        ),
      )
      ..add(
        DateTimeRange(
          start: DateTimeHelper.findFirstDateOfTheWeek(now),
          end: DateTimeHelper.findLastDateOfTheWeek(now),
        ),
      )
      ..add(
        DateTimeRange(
          start: DateTimeHelper.findFirstDateOfTheMonth(now),
          end: DateTimeHelper.findLastDateOfTheMonth(now),
        ),
      );

    return _dateOptions;
  }

  String _getStringValue(BuildContext? context, DateTimeRange date) {
    final isSameDay = DateTimeHelper.isEqualDateByDay(date.start, date.end);
    final isToday = DateTimeHelper.isThisDay(date.start, date.end);
    final isYesterday = DateTimeHelper.isPreviousDay(date.start, date.end);
    final isThisWeek = DateTimeHelper.isThisWeek(date.start, date.end);
    final isThisMonth = DateTimeHelper.isThisMonth(date.start, date.end);

    final format = DateFormat('dd/MM/yyyy');

    if (context == null) {
      if (isToday) {
        return 'Today';
      } else if (isYesterday) {
        return 'Yesterday';
      } else if (isSameDay) {
        return format.format(date.start);
      } else if (isThisWeek) {
        return 'This Week';
      } else if (isThisMonth) {
        return 'This Month';
      }
    } else {
      if (isToday) {
        return context.l10n.today;
      } else if (isYesterday) {
        return context.l10n.yesterday;
      } else if (isSameDay) {
        return format.format(date.start);
      } else if (isThisWeek) {
        return context.l10n.thisWeek;
      } else if (isThisMonth) {
        return context.l10n.thisMonth;
      }
    }

    return '${format.format(date.start)}'
        ' - ${format.format(date.end)}';
  }
}
