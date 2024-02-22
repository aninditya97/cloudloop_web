import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/domain/entities/enums/invitation_status.dart';
import 'package:cloudloop_mobile/features/family/presentation/presentation.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvitationsDataSection extends StatefulWidget {
  const InvitationsDataSection({Key? key, this.searchController})
      : super(key: key);

  final TextEditingController? searchController;

  @override
  State<InvitationsDataSection> createState() => _InvitationsDataSectionState();
}

class _InvitationsDataSectionState extends State<InvitationsDataSection> {
  final _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchData(1);
    _scrollController.addListener(_onScroll);
  }

  void _fetchData(int page) {
    context.read<InvitationsMemberBloc>().add(
          FetchInvitationsMemberEvent(
            page: page,
            perPage: 20,
          ),
        );
  }

  void _acceptInvitation(int id) {
    context.read<AcceptFamilyInvitationBloc>().add(
          AcceptFamilyInvitationFetched(id: id),
        );
  }

  void _rejectInvitation(int id) {
    context.read<RejectFamilyInvitationBloc>().add(
          RejectFamilyInvitationFetched(id: id),
        );
  }

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () async {
        _fetchData(1);
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<AcceptFamilyInvitationBloc, AcceptFamilyInvitationState>(
            listener: (context, state) {
              if (state is AcceptFamilyInvitationFailure) {
                _dismissLoadingDialog();
                _onFailure(state.failure);
              } else if (state is AcceptFamilyInvitationSuccess) {
                // _dismissLoadingDialog();
                // _onSuccess(_l10n.acceptInvitation);
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted) {
                    _dismissLoadingDialog();
                  }
                });
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted) {
                    _onSuccess(_l10n.acceptInvitation);
                  }
                });
              } else if (state is AcceptFamilyInvitationLoading) {
                _showLoadingDialog(context);
              }
            },
          ),
          BlocListener<RejectFamilyInvitationBloc, RejectFamilyInvitationState>(
            listener: (context, state) {
              if (state is RejectFamilyInvitationFailure) {
                _dismissLoadingDialog();
                _onFailure(state.failure);
              } else if (state is RejectFamilyInvitationSuccess) {
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted) {
                    _dismissLoadingDialog();
                  }
                });
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted) {
                    _onSuccess(_l10n.rejectInvitation);
                  }
                });
              } else if (state is RejectFamilyInvitationLoading) {
                _showLoadingDialog(context);
              }
            },
          ),
        ],
        child: BlocBuilder<InvitationsMemberBloc, InvitationsMemberState>(
          builder: (context, state) {
            if (state is InvitationsMemberSuccess) {
              _currentPage = state.page;
              final _itemList = state.data
                  .where((e) => e.status == InvitationStatus.status3)
                  .toList();
              if (_itemList.isEmpty) {
                return IllustrationMessage(
                  imagePath: MainAssets.noUserWithName,
                  title: _l10n.noInvites,
                  message: _l10n.inviteFamily,
                );
              } else {
                return _SuccessContent(
                  successState: state,
                  scrollController: _scrollController,
                  onAccepted: _acceptInvitation,
                  onRejected: _rejectInvitation,
                  paginationPage: state.page,
                );
              }
            } else if (state is InvitationsMemberFailure) {
              return const SizedBox();
              // FailureLoadMessage(
              //   onReloadData: () => _fetchData(1),
              //   message: state.failure.message,
              // );
            }

            return const _LoadingContent();
          },
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
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
      _fetchData(_currentPage);
    });
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
    required this.onAccepted,
    required this.onRejected,
  }) : super(key: key);

  final InvitationsMemberSuccess successState;
  final ScrollController? scrollController;
  final ValueChanged<int> onAccepted;
  final ValueChanged<int> onRejected;
  final int paginationPage;

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
            final _item = successState.data[i];
            return PendingInvitationComponent(
              name: _item.source!.name,
              avatar: _item.source?.avatar ?? '',
              id: _item.id,
              userId: _item.source!.id.toString(),
              status: '',
              onAccepted: onAccepted.call,
              onRejected: onRejected.call,
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
      itemBuilder: (_, i) => const PendingInvitationSkeleton(),
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.grey[300],
      ),
      itemCount: 10,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
    );
  }
}
