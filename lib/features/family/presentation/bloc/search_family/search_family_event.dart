part of 'search_family_bloc.dart';

abstract class SearchFamilyEvent extends Equatable {}

class FetchSearchFamilyEvent extends SearchFamilyEvent {
  FetchSearchFamilyEvent({
    required this.page,
    required this.perPage,
    this.query,
  });

  final int page;
  final int perPage;
  final String? query;

  @override
  List<Object?> get props => [query];
}
