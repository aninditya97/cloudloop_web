part of 'input_insulin_bloc.dart';

class InputInsulinState extends Equatable {
  const InputInsulinState({
    required this.insulin,
    required this.status,
    this.failure,
  });

  const InputInsulinState.pure()
      : this(
          status: FormzStatus.pure,
          insulin: const NotNullFormz.pure(),
        );

  final NotNullFormz<double> insulin;
  final FormzStatus status;
  final ErrorException? failure;

  InputInsulinState copyWith({
    NotNullFormz<double>? insulin,
    FormzStatus? status,
    ErrorException? failure,
  }) {
    return InputInsulinState(
      insulin: insulin ?? this.insulin,
      status: status ?? this.status,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [insulin, status, failure];
}
