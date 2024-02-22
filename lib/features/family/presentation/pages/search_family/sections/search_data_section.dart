import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchFamilysDataSection extends StatefulWidget {
  const SearchFamilysDataSection({Key? key, this.searchController})
      : super(key: key);

  final TextEditingController? searchController;

  @override
  State<SearchFamilysDataSection> createState() =>
      _SearchFamilysDataSectionState();
}

class _SearchFamilysDataSectionState extends State<SearchFamilysDataSection> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _searchName;
  int _currentPage = 1;
  bool _isLoadingDialogOpen = false;
  bool _onSearching = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
  }

  void _onSearch(String v, int page) {
    context
        .read<SearchFamilyBloc>()
        .add(FetchSearchFamilyEvent(page: page, perPage: 10, query: v));
  }

  void _onConnect(String email) {
    context.read<InviteFamilyBloc>().add(InviteFamilyFetched(email: email));
  }

  void _onRemove(int id) {
    context.read<RemoveFamilyMemberBloc>().add(
          RemoveFamilyMemberFetched(id: id),
        );
  }

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.appPadding,
          ),
          child: TextFormField(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.blueGray[400]!,
                  width: 2,
                ),
              ),
              hintText: _l10n.searchUsername,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear.call();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear_rounded),
                    )
                  : null,
            ),
            controller: _searchController,
            onFieldSubmitted: (String? value) {
              _onSearch(value.toString(), 1);
              _onSearching = true;
              setState(() {
                _searchName = value.toString();
              });
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _currentPage = 1;
              _onSearch(_searchName ?? '', _currentPage);
            },
            child: MultiBlocListener(
              listeners: [
                BlocListener<InviteFamilyBloc, InviteFamilyState>(
                  listener: (context, state) {
                    if (state is InviteFamilyFailure) {
                      _dismissLoadingDialog();
                      _onFailure(state.failure);
                    } else if (state is InviteFamilyLoading) {
                      _showLoadingDialog();
                    } else if (state is InviteFamilySuccess) {
                      _dismissLoadingDialog();
                      _onSuccess(_l10n.invitationSent);
                    }
                  },
                ),
                BlocListener<RemoveFamilyMemberBloc, RemoveFamilyMemberState>(
                  listener: (context, state) {
                    if (state is RemoveFamilyMemberFailure) {
                      _dismissLoadingDialog();
                      _onFailure(state.failure);
                    } else if (state is RemoveFamilyMemberLoading) {
                      _showLoadingDialog();
                    } else if (state is RemoveFamilyMemberSuccess) {
                      _dismissLoadingDialog();
                      _onSuccess(_l10n.deleteUser);
                    }
                  },
                ),
              ],
              child: BlocBuilder<SearchFamilyBloc, SearchFamilyState>(
                builder: (context, state) {
                  if (state is SearchFamilySuccess) {
                    _currentPage = state.page;
                    if (state.data.isEmpty) {
                      return Container(
                        alignment: Alignment.center,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          children: [
                            if (_onSearching) ...[
                              Center(
                                child: IllustrationMessage(
                                  imagePath: MainAssets.noUserWithName,
                                  title: _l10n
                                      .noUserWithName(_searchController.text),
                                  message: _l10n.makeSureInput,
                                ),
                              )
                            ] else ...[
                              Center(
                                child: IllustrationMessage(
                                  imagePath: MainAssets.searchFamilyMember,
                                  title: _l10n.searchFamilyMember,
                                  message: _l10n.searchFamilyMemberByUsername,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    } else {
                      return _SuccessContent(
                        successState: state,
                        scrollController: _scrollController,
                        paginationPage: state.page,
                        onConnect: _onConnect,
                        onRemove: _onRemove,
                      );
                    }
                  } else if (state is SearchFamilyLoading) {
                    return const _LoadingContent();
                  }
                  return Padding(
                    padding: const EdgeInsets.all(Dimens.dp16),
                    child: Center(
                      child: IllustrationMessage(
                        imagePath: MainAssets.searchFamilyMember,
                        title: _l10n.searchFamilyMember,
                        message: _l10n.searchFamilyMemberByUsername,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // void _onScroll() {
  //   final maxScroll = _scrollController.position.maxScrollExtent;
  //   final currentScroll = _scrollController.position.pixels;
  //   // if (currentScroll < maxScroll) {
  //     _onSearch(_searchName ?? '', _currentPage + 1);
  //   // }
  // }
  void _onScroll() {
    if (_isBottom) _onSearch(_searchName ?? '', _currentPage + 1);
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showLoadingDialog() {
    if (!_isLoadingDialogOpen) {
      setState(() {
        _isLoadingDialogOpen = true;
      });

      context.showLoadingDialog().whenComplete(() {
        if (mounted) {
          setState(() {
            _isLoadingDialogOpen = false;
          });
        }
      });
    }
  }

  void _dismissLoadingDialog() {
    if (_isLoadingDialogOpen) {
      Navigator.of(context).pop();
    }
  }

  void _onFailure(ErrorException failure) {
    context.showErrorSnackBar(failure.message);
  }

  Future _onSuccess(String message) async {
    context.showSuccessSnackBar(message);
    Future.delayed(const Duration(seconds: 1), () {
      _onSearch(_searchName ?? '', _currentPage);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    Key? key,
    required this.successState,
    this.scrollController,
    required this.paginationPage,
    this.onConnect,
    this.onRemove,
  }) : super(key: key);

  final SearchFamilySuccess successState;
  final ScrollController? scrollController;
  final int paginationPage;
  final ValueChanged<String>? onConnect;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      children: [
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (_, i) {
            final item = successState.data[i];
            return SearchUserComponent(
              name: item.name,
              id: item.id,
              avatar: item.avatar ?? '',
              status: item.connection?.status ?? ConnectionStatus.status1,
              onConnect: () {
                onConnect?.call(item.email);
              },
            );
          },
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: Colors.grey[300],
          ),
          itemCount: successState.data.length,
        ),
        if (!successState.hasReachedMax) ...[
          const Divider(),
          const SearchUserSkeleton(),
        ] else if (paginationPage > 1) ...[
          const SizedBox(height: Dimens.dp16),
          // const ReachesBottomMessage(),
        ],
      ],
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        vertical: Dimens.dp24,
        horizontal: Dimens.dp16,
      ),
      itemBuilder: (_, i) => const SearchUserSkeleton(),
      separatorBuilder: (_, __) => const Divider(),
      itemCount: 10,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
    );
  }
}
