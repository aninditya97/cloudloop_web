part of 'input_insulin_bloc.dart';

abstract class InputInsulinEvent extends Equatable {
  const InputInsulinEvent();

  @override
  List<Object?> get props => [];
}

class InputInsulinValueChanged extends InputInsulinEvent {
  const InputInsulinValueChanged({
    required this.value,
  });

  final double? value;

  @override
  List<Object?> get props => [value];
}

class InputInsulinSubmitted extends InputInsulinEvent {
  const InputInsulinSubmitted({
    this.source = ReportSource.user,
    this.announceMeal,
    this.autoMode,
    this.iob,
    this.hypoPrevention,
  });

  final ReportSource source;
  final bool? announceMeal;
  final bool? autoMode;
  final double? iob;
  final int? hypoPrevention;

  @override
  List<Object?> get props => [
        source,
        announceMeal,
        autoMode,
        iob,
        hypoPrevention,
      ];

  //kai_20221208 added to support sensor updating
  // const InputInsulinSubmitted.sensor({this.source = ReportSource.sensor});
}
