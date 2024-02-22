part of 'carbohydrate_report_bloc.dart';

abstract class CarbohydrateReportState extends Equatable {
  const CarbohydrateReportState();

  @override
  List<Object> get props => [];
}

class CarbohydrateReportLoading extends CarbohydrateReportState {
  const CarbohydrateReportLoading();
}

class CarbohydrateReportSuccess extends CarbohydrateReportState {
  const CarbohydrateReportSuccess(this.data);

  final CarbohydrateReportData data;

  @override
  List<Object> get props => [data];
}

class CarbohydrateReportFailure extends CarbohydrateReportState {
  const CarbohydrateReportFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}
