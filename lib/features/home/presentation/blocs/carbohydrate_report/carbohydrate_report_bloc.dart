import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';

part 'carbohydrate_report_event.dart';
part 'carbohydrate_report_state.dart';

class CarbohydrateReportBloc
    extends Bloc<CarbohydrateReportEvent, CarbohydrateReportState> {
  CarbohydrateReportBloc({required this.carbohydrateReport})
      : super(const CarbohydrateReportLoading()) {
    on<CarbohydrateReportFetched>(_onDataFetched);
  }

  final GetCarbohydrateReportUseCase carbohydrateReport;

  Future _onDataFetched(
    CarbohydrateReportFetched event,
    Emitter<CarbohydrateReportState> emit,
  ) async {
    try {
      emit(const CarbohydrateReportLoading());
      final result = await carbohydrateReport(
        CarbohydrateReportParams(
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          CarbohydrateReportFailure.new,
          CarbohydrateReportSuccess.new,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        CarbohydrateReportFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}
