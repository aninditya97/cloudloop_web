import 'package:equatable/equatable.dart';

class ChartData extends Equatable {
  const ChartData({
    required this.x,
    required this.y,
  });

  final DateTime x;
  final num y;

  @override
  List<Object?> get props => [
        x,
        y,
      ];
}
