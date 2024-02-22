part of 'insulin_report_bloc.dart';

abstract class InsulinReportEvent extends Equatable {
  const InsulinReportEvent();

  @override
  List<Object?> get props => [];
}

class InsulinReportFetched extends InsulinReportEvent {
  const InsulinReportFetched({
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
