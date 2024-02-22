part of 'insulin_report_bloc.dart';

abstract class InsulinReportState extends Equatable {
  const InsulinReportState();

  @override
  List<Object> get props => [];
}

class InsulinReportLoading extends InsulinReportState {
  const InsulinReportLoading();
}

class InsulinReportSuccess extends InsulinReportState {
  const InsulinReportSuccess(this.data);

  final InsulinReportData data;

  @override
  List<Object> get props => [data];
}

class InsulinReportFailure extends InsulinReportState {
  const InsulinReportFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}
