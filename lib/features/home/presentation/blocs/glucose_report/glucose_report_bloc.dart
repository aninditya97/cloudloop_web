import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';

part 'glucose_report_event.dart';
part 'glucose_report_state.dart';

class GlucoseReportBloc extends Bloc<GlucoseReportEvent, GlucoseReportState> {
  GlucoseReportBloc({required this.glucoseReport})
      : super(const GlucoseReportLoading()) {
    on<GlucoseReportFetched>(_onDataFetched);
  }

  final GetGlucoseReportUseCase glucoseReport;

  Future _onDataFetched(
    GlucoseReportFetched event,
    Emitter<GlucoseReportState> emit,
  ) async {
    try {
      emit(const GlucoseReportLoading());
      final result = await glucoseReport(
        GlucoseReportParams(
          startDate: event.startDate,
          endDate: event.endDate,
          filter: event.filter,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          GlucoseReportFailure.new,
          GlucoseReportSuccess.new,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        GlucoseReportFailure(
          ErrorCodeException(
            message: error.toString(),
          ),
        ),
      );
    }
  }
}
