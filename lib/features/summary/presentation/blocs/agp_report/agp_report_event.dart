part of 'agp_report_bloc.dart';

abstract class AgpReportEvent extends Equatable {
  const AgpReportEvent();

  @override
  List<Object?> get props => [];
}

class AgpReportFetched extends AgpReportEvent {
  const AgpReportFetched({
    this.page,
    this.startDate,
    this.endDate,
    this.userId,
  });

  final int? page;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? userId;

  @override
  List<Object?> get props => [
        page,
        startDate,
        endDate,
        userId,
      ];
}
