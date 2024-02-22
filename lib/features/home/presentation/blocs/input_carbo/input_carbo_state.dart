part of 'input_carbo_bloc.dart';

class InputCarbohydrateState extends Equatable {
  const InputCarbohydrateState({
    required this.carbohydrate,
    required this.foodType,
    required this.date,
    required this.time,
    required this.status,
    this.failure,
  });

  const InputCarbohydrateState.pure()
      : this(
          status: FormzStatus.pure,
          carbohydrate: const NotNullFormz.pure(),
          foodType: const NotNullFormz.pure(),
          date: const UnValidatedFormz.dirty(null),
          time: const UnValidatedFormz.dirty(null),
        );

  final NotNullFormz<double> carbohydrate;
  final NotNullFormz<FoodType> foodType;
  final UnValidatedFormz<DateTime> date;
  final UnValidatedFormz<TimeOfDay> time;

  final FormzStatus status;
  final ErrorException? failure;

  InputCarbohydrateState copyWith({
    NotNullFormz<double>? carbohydrate,
    NotNullFormz<FoodType>? foodType,
    UnValidatedFormz<DateTime>? date,
    UnValidatedFormz<TimeOfDay>? time,
    FormzStatus? status,
    ErrorException? failure,
  }) {
    return InputCarbohydrateState(
      carbohydrate: carbohydrate ?? this.carbohydrate,
      foodType: foodType ?? this.foodType,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props =>
      [carbohydrate, foodType, date, time, status, failure];
}
