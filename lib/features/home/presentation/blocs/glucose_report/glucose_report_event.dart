part of 'glucose_report_bloc.dart';

abstract class GlucoseReportEvent extends Equatable {
  const GlucoseReportEvent();

  @override
  List<Object?> get props => [];
}

class GlucoseReportFetched extends GlucoseReportEvent {
  const GlucoseReportFetched({
    this.startDate,
    this.endDate,
    required this.filter,
  });
  final DateTime? startDate;
  final DateTime? endDate;
  final bool filter;

  @override
  List<Object?> get props => [startDate, endDate, filter];
}
