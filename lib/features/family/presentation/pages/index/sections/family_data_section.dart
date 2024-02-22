import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FamilysDataSection extends StatefulWidget {
  const FamilysDataSection({Key? key, this.searchController}) : super(key: key);

  final TextEditingController? searchController;

  @override
  State<FamilysDataSection> createState() => _FamilysDataSectionState();
}

class _FamilysDataSectionState extends State<FamilysDataSection> {
  final _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchData(1);
    _scrollController.addListener(_onScroll);
  }

  void _fetchData(int page) {
    context.read<FamilyMemberBloc>().add(
          FetchFamilyMemberEvent(
            page: page,
            perPage: 20,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () async {
        _fetchData(1);
      },
      child: BlocBuilder<FamilyMemberBloc, FamilyMemberState>(
        builder: (context, state) {
          if (state is FamilyMemberSuccess) {
            _currentPage = state.page;
            if (state.data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (builder) => const MainFamilyPage(),
                          ),
                        );
                      },
                      child: Image.asset(
                        MainAssets.noConnectedFamilyMember,
                        width: 270,
                      ),
                    ),
                    const SizedBox(height: Dimens.appPadding),
                    HeadingText5(
                      text: _l10n.noConnectedFamilyMember,
                      textColor: AppColors.blueGray[600],
                    ),
                    const SizedBox(height: Dimens.small),
                    SubtitleText(
                      text: _l10n.familyMemberEmptyMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimens.appPadding),
                    SizedBox(
                      width: 170,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (builder) => const SearchFamilyPage(),
                            ),
                          );
                        },
                        child: Center(
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: Dimens.dp18),
                              const SizedBox(width: Dimens.dp6),
                              HeadingText4(
                                text: _l10n.createFamily,
                                textColor: AppColors.whiteColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return _SuccessContent(
                successState: state,
                scrollController: _scrollController,
                paginationPage: state.page,
                onChange: () {
                  _fetchData(1);
                },
              );
            }
          } else if (state is FamilyMemberFailure) {
            return const SizedBox();
            // FailureLoadMessage(
            //   onReloadData: () => _fetchData(1),
            //   message: state.failure.message,
            // );
          }

          return const _LoadingContent();
        },
      ),
    );
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > maxScroll) {
      _fetchData(_currentPage + 1);
    }
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
    this.onChange,
  }) : super(key: key);

  final FamilyMemberSuccess successState;
  final ScrollController? scrollController;
  final int paginationPage;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.dp16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (_, i) {
          final _item = successState.data[i];
          final _adminId = getIdAdmin(successState.data);
          return Padding(
            padding: const EdgeInsets.all(Dimens.dp4),
            child: FamilyMemberComponent(
              avatar: _item.user?.avatar ?? '',
              name: _item.user?.name ?? '',
              statusLevel: _item.user?.summary?.glucose?.level ??
                  BloodGlucoseLevel.status1,
              value: _item.user?.summary?.glucose?.value ?? 0,
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => FamilyMemberDetailPage(
                      id: _item.id,
                      name: _item.user?.name ?? '',
                      label: _item.label ?? '',
                      avatar: _item.user?.avatar,
                      role: _item.role,
                      userId: _item.user!.id,
                      adminId: _adminId,
                    ),
                  ),
                );

                if (result != null) {
                  onChange?.call();
                }
              },
            ),
          );
        },
        itemCount: successState.data.length,
      ),
    );
  }

  int getIdAdmin(List<FamilyData> dataList) {
    var _idAdmin = -1;
    for (final data in dataList) {
      if (data.role == UserRole.admin) {
        if (data.user != null) {
          _idAdmin = data.user!.id;
        }
      }
    }
    return _idAdmin;
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.dp16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (_, i) {
          return const Padding(
            padding: EdgeInsets.all(Dimens.dp4),
            child: FamilyMemberSkeleton(),
          );
        },
        itemCount: 4,
      ),
    );
  }
}
