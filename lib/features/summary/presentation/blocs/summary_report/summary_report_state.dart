part of 'summary_report_bloc.dart';

abstract class SummaryReportState extends Equatable {
  const SummaryReportState();

  @override
  List<Object> get props => [];
}

class SummaryReportLoading extends SummaryReportState {
  const SummaryReportLoading();
}

class SummaryReportSuccess extends SummaryReportState {
  const SummaryReportSuccess(this.data);

  final SummaryReport data;

  @override
  List<Object> get props => [data];
}

class SummaryReportFailure extends SummaryReportState {
  const SummaryReportFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}
