part of 'glucose_report_bloc.dart';

abstract class GlucoseReportState extends Equatable {
  const GlucoseReportState();

  @override
  List<Object> get props => [];
}

class GlucoseReportLoading extends GlucoseReportState {
  const GlucoseReportLoading();
}

class GlucoseReportSuccess extends GlucoseReportState {
  const GlucoseReportSuccess(this.data);

  final GlucoseReportData data;

  @override
  List<Object> get props => [data];
}

class GlucoseReportFailure extends GlucoseReportState {
  const GlucoseReportFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}
