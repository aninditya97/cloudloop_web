import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:equatable/equatable.dart';

part 'agp_report_event.dart';
part 'agp_report_state.dart';

class AgpReportBloc extends Bloc<AgpReportEvent, AgpReportState> {
  AgpReportBloc({required this.getAGPReportUseCase})
      : super(const AgpReportLoading()) {
    on<AgpReportFetched>(_onDataFetched);
  }

  final GetAGPReportUseCase getAGPReportUseCase;

  Future _onDataFetched(
    AgpReportFetched event,
    Emitter<AgpReportState> emit,
  ) async {
    try {
      emit(const AgpReportLoading());
      final result = await getAGPReportUseCase(
        AgpReportParams(
          page: event.page,
          startDate: event.startDate,
          endDate: event.endDate,
          userId: event.userId,
        ),
      );

      if (emit.isDone) return;

      emit(result.fold(AgpReportFailure.new, AgpReportSuccess.new));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(AgpReportFailure(ErrorCodeException(message: error.toString())));
    }
  }
}
