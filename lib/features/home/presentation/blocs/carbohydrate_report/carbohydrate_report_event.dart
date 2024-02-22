part of 'carbohydrate_report_bloc.dart';

abstract class CarbohydrateReportEvent extends Equatable {
  const CarbohydrateReportEvent();

  @override
  List<Object?> get props => [];
}

class CarbohydrateReportFetched extends CarbohydrateReportEvent {
  const CarbohydrateReportFetched({
    this.startDate,
    this.endDate,
  });
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [startDate, endDate];
}
