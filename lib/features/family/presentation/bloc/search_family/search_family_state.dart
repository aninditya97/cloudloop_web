part of 'search_family_bloc.dart';

abstract class SearchFamilyState extends Equatable {}

class SearchFamilyInitial extends SearchFamilyState {
  @override
  List<Object?> get props => [];
}

class SearchFamilyLoading extends SearchFamilyState {
  @override
  List<Object?> get props => [];
}

class SearchFamilySuccess extends SearchFamilyState {
  SearchFamilySuccess({
    required this.data,
    required this.hasReachedMax,
    required this.page,
  });

  final List<UserData> data;
  final bool hasReachedMax;
  final int page;

  @override
  List<Object> get props => [data];
}

class SearchFamilyFailure extends SearchFamilyState {
  SearchFamilyFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}
