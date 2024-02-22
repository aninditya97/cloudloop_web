part of 'agp_report_bloc.dart';

abstract class AgpReportState extends Equatable {
  const AgpReportState();

  @override
  List<Object> get props => [];
}

class AgpReportLoading extends AgpReportState {
  const AgpReportLoading();
}

class AgpReportSuccess extends AgpReportState {
  const AgpReportSuccess(this.data);

  final AGPReport data;

  @override
  List<Object> get props => [data];
}

class AgpReportFailure extends AgpReportState {
  const AgpReportFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}
