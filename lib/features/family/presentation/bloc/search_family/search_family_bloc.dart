import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'search_family_event.dart';
part 'search_family_state.dart';

class SearchFamilyBloc extends Bloc<SearchFamilyEvent, SearchFamilyState> {
  SearchFamilyBloc({required this.searchFamilyUseCase})
      : super(SearchFamilyInitial()) {
    on<FetchSearchFamilyEvent>(_onDataFetched);
  }

  final SearchFamilyUseCase searchFamilyUseCase;

  Future _onDataFetched(
    FetchSearchFamilyEvent event,
    Emitter<SearchFamilyState> emit,
  ) async {
    if (!_isAllow(event)) return;

    final currentState = state;

    if (event.page == 1) {
      emit(SearchFamilyLoading());
    }
    try {
      final _result = await searchFamilyUseCase(
        SearchPaginateParams(
          page: event.page,
          perPage: event.perPage,
          query: event.query ?? '',
        ),
      );

      _result.fold((l) {
        if (event.page == 1) {
          emit(SearchFamilyFailure(l));
        }
      }, (r) {
        if (currentState is SearchFamilyLoading || event.page == 1) {
          emit(
            SearchFamilySuccess(
              data: r.data,
              hasReachedMax: r.data.length < event.perPage,
              page: r.meta.page,
            ),
          );
        } else if (currentState is SearchFamilySuccess &&
            currentState.page < (r.meta.page)) {
          emit(
            SearchFamilySuccess(
              data: currentState.data + r.data,
              hasReachedMax: r.data.length < event.perPage,
              page: r.meta.page,
            ),
          );
        }
      });
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SearchFamilyFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }

  bool _isAllow(FetchSearchFamilyEvent event) {
    if (!_hasReachedMax(state) || event.page == 1) {
      if (state is SearchFamilySuccess) {
        final currentState = state as SearchFamilySuccess;
        if (event.page == 1 || event.page > currentState.page) {
          return true;
        }
      } else if (event.page == 1) {
        return true;
      }
    }
    return false;
  }

  bool _hasReachedMax(SearchFamilyState state) =>
      state is SearchFamilySuccess && state.hasReachedMax;
}
