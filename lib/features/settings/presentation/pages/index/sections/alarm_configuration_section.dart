import 'package:cloudloop_mobile/features/home/presentation/blocs/input_alarm_profile/input_alarm_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class AlarmConfigurationInfo extends StatelessWidget {
  final bool isRepeatEnabled;
  final DateTime? selectedDate;
  final List<int>? selectedDays;

  AlarmConfigurationInfo({
    required this.isRepeatEnabled,
    required this.selectedDate,
    required this.selectedDays,
  });

  @override
  Widget build(BuildContext context) {
    if (isRepeatEnabled) {
      // Show days picker
      final selectedDaysText =
      InputAlarmProfileBloc.formatSelectedDaysText(
          selectedDays);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedDaysText,
            style: TextStyle(fontSize: 12.0),
          ),
        ],
      );
    } else {
      // Show date picker
      return GestureDetector(
        child: Text(
          selectedDate != null
              ? DateFormat('EEE, MMM d').format(selectedDate!)
              : 'No date selected',
          style: TextStyle(fontSize: 12.0),
        ),
      );
    }
  }
}
