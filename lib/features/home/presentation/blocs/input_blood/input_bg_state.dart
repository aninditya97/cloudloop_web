part of 'input_bg_bloc.dart';

class InputBloodGlucoseState extends Equatable {
  const InputBloodGlucoseState({
    required this.glucose,
    required this.status,
    this.failure,
  });

  const InputBloodGlucoseState.pure()
      : this(
          status: FormzStatus.pure,
          glucose: const NotNullFormz.pure(),
        );

  final NotNullFormz<double> glucose;
  final FormzStatus status;
  final ErrorException? failure;

  InputBloodGlucoseState copyWith({
    NotNullFormz<double>? glucose,
    FormzStatus? status,
    ErrorException? failure,
  }) {
    return InputBloodGlucoseState(
      glucose: glucose ?? this.glucose,
      status: status ?? this.status,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [glucose, status, failure];
}
