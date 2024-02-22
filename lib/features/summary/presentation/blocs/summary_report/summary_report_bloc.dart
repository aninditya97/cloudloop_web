import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:equatable/equatable.dart';

part 'summary_report_event.dart';
part 'summary_report_state.dart';

class SummaryReportBloc extends Bloc<SummaryReportEvent, SummaryReportState> {
  SummaryReportBloc({required this.summary})
      : super(const SummaryReportLoading()) {
    on<SummaryReportFetched>(_onDataFetched);
  }

  final GetSummaryReportUseCase summary;

  Future _onDataFetched(
    SummaryReportFetched event,
    Emitter<SummaryReportState> emit,
  ) async {
    try {
      emit(const SummaryReportLoading());
      final result = await summary(
        SummaryReportParams(
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );

      if (emit.isDone) return;

      emit(result.fold(SummaryReportFailure.new, SummaryReportSuccess.new));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(SummaryReportFailure(ErrorCodeException(message: error.toString())));
    }
  }
}
