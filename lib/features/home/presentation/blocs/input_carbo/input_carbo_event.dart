part of 'input_carbo_bloc.dart';

abstract class InputCarbohydrateEvent extends Equatable {
  const InputCarbohydrateEvent();

  @override
  List<Object?> get props => [];
}

class InputCarbohydrateValueChanged extends InputCarbohydrateEvent {
  const InputCarbohydrateValueChanged({required this.value});

  final double? value;

  @override
  List<Object?> get props => [value];
}

class InputCarbohydrateFoodTypeChanged extends InputCarbohydrateEvent {
  const InputCarbohydrateFoodTypeChanged({required this.foodType});

  final FoodType foodType;

  @override
  List<Object?> get props => [foodType];
}

class InputCarbohydrateDateChanged extends InputCarbohydrateEvent {
  const InputCarbohydrateDateChanged({required this.date});

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class InputCarbohydrateTimeChanged extends InputCarbohydrateEvent {
  const InputCarbohydrateTimeChanged({required this.time});

  final TimeOfDay time;

  @override
  List<Object?> get props => [time];
}

class InputCarbohydrateSubmitted extends InputCarbohydrateEvent {
  const InputCarbohydrateSubmitted({this.source = ReportSource.user});

  final ReportSource source;

  @override
  List<Object?> get props => [source];
}
