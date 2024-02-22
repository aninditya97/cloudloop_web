import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';

part 'insulin_report_event.dart';
part 'insulin_report_state.dart';

class InsulinReportBloc extends Bloc<InsulinReportEvent, InsulinReportState> {
  InsulinReportBloc({required this.insulinReport})
      : super(const InsulinReportLoading()) {
    on<InsulinReportFetched>(_onDataFetched);
  }

  final GetInsulinReportUseCase insulinReport;

  Future _onDataFetched(
    InsulinReportFetched event,
    Emitter<InsulinReportState> emit,
  ) async {
    try {
      emit(const InsulinReportLoading());
      final result = await insulinReport(
        InsulinReportParams(
          startDate: event.startDate,
          endDate: event.endDate,
          filter: event.filter,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          InsulinReportFailure.new,
          InsulinReportSuccess.new,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        InsulinReportFailure(
          ErrorCodeException(
            message: error.toString(),
          ),
        ),
      );
    }
  }
}
