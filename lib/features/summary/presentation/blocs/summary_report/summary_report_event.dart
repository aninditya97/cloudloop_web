part of 'summary_report_bloc.dart';

abstract class SummaryReportEvent extends Equatable {
  const SummaryReportEvent();

  @override
  List<Object?> get props => [];
}

class SummaryReportFetched extends SummaryReportEvent {
  const SummaryReportFetched({
    this.startDate,
    this.endDate,
  });
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [
        startDate,
        endDate,
      ];
}
