import 'package:equatable/equatable.dart';

class AutoModeStatus extends Equatable {
  const AutoModeStatus({
    required this.status,
  });

  final int status;

  @override
  List<Object?> get props => [status];
}
