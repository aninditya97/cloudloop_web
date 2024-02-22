part of 'input_bg_bloc.dart';

abstract class InputBloodGlucoseEvent extends Equatable {
  const InputBloodGlucoseEvent();

  @override
  List<Object?> get props => [];
}

class InputBloodGlucoseValueChanged extends InputBloodGlucoseEvent {
  const InputBloodGlucoseValueChanged({required this.value});

  final double? value;

  @override
  List<Object?> get props => [value];
}

class InputBloodGlucoseSubmitted extends InputBloodGlucoseEvent {
  const InputBloodGlucoseSubmitted({
    this.source = ReportSource.user,
    this.time,
  });

  final ReportSource source;
  final DateTime? time;

  @override
  List<Object?> get props => [
        source,
        time,
      ];
}
