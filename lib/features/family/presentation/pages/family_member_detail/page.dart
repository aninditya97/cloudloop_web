import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/family/presentation/pages/family_member_detail/sections/section.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/component.dart';
import 'package:cloudloop_mobile/features/settings/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:get_it/get_it.dart';

class FamilyMemberDetailPage extends StatelessWidget {
  const FamilyMemberDetailPage({
    Key? key,
    required this.id,
    required this.userId,
    required this.name,
    required this.label,
    required this.role,
    required this.adminId,
    this.avatar,
  }) : super(key: key);

  final int id;
  final int userId;
  final String name;
  final String label;
  final UserRole role;
  final int adminId;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I<FamilyMemberDetailBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<LeaveFamilyBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<RemoveFamilyMemberBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<ProfileBloc>(),
        ),
      ],
      child: _FamilyMemberDetailView(
        id: id,
        userId: userId,
        name: name,
        label: label,
        avatar: avatar,
        role: role,
        adminId: adminId,
      ),
    );
  }
}

class _FamilyMemberDetailView extends StatefulWidget {
  const _FamilyMemberDetailView({
    Key? key,
    required this.id,
    required this.userId,
    required this.name,
    required this.label,
    required this.role,
    required this.adminId,
    this.avatar,
  }) : super(key: key);

  final int id;
  final int userId;
  final String name;
  final String label;
  final UserRole role;
  final int adminId;
  final String? avatar;

  @override
  State<_FamilyMemberDetailView> createState() =>
      _FamilyMemberDetailViewState();
}

class _FamilyMemberDetailViewState extends State<_FamilyMemberDetailView> {
  bool _isLoadingDialogOpen = false;
  String? _label;
  int? _userId;
  bool isChange = false;

  void _fetchData() {
    context.read<FamilyMemberDetailBloc>().add(
          FamilyMemberDetailFetched(id: widget.id),
        );
  }

  void _fetchProfileData() {
    context.read<ProfileBloc>().add(const ProfileFetched());
  }

  void _onLeave() {
    context.read<LeaveFamilyBloc>().add(
          LeaveFamilyFetched(id: widget.id),
        );
  }

  void _onRemove(int id) {
    context.read<RemoveFamilyMemberBloc>().add(
          RemoveFamilyMemberFetched(id: id),
        );
  }

  @override
  void initState() {
    _fetchData();
    _fetchProfileData();
    _label = widget.label;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => setState(() {}),
    );
    return WillPopScope(
      onWillPop: () {
        //trigger leaving and use own data
        Navigator.pop(context, isChange);

        //we need to return a future
        return Future.value(isChange);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          foregroundColor: AppColors.primarySolidColor,
          centerTitle: false,
          actions: [
            if (_userId == widget.userId) ...[
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (builder) => EditFamilyNamePage(
                        id: widget.id,
                        name: widget.name,
                        label: _label ?? widget.label,
                        avatar: widget.avatar ?? '',
                      ),
                    ),
                  );
                  if (result != null) {
                    _fetchData();
                    setState(() {});
                  }
                },
                icon: const Icon(
                  Icons.mode_edit_outline_outlined,
                ),
              ),
            ],
            if (_userId != widget.userId && widget.adminId == _userId) ...[
              IconButton(
                onPressed: () {
                  _showRemoveFamilyConfirmationSheet(context, widget.id);
                },
                icon: const Icon(Icons.group_off_outlined),
              ),
            ] else if (_userId == widget.userId &&
                widget.adminId != _userId) ...[
              IconButton(
                onPressed: () {
                  _showLeaveFamilyConfirmationSheet(context, widget.id);
                },
                icon: const Icon(Icons.group_off_outlined),
              ),
            ]
          ],
          title: Row(
            children: [
              ClipOval(
                child: SizedBox.fromSize(
                  size: const Size.fromRadius(Dimens.dp20), // Image radius
                  child: Image.network(
                    widget.avatar ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, url, error) => ProfilePicture(
                      name: widget.name,
                      fontsize: Dimens.dp28,
                      radius: Dimens.dp36,
                      count: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Dimens.dp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeadingText4(
                      text: widget.name,
                      maxLines: 2,
                    ),
                    const SizedBox(height: Dimens.small),
                    SubtitleText(
                      text: _label ?? '',
                      textColor: AppColors.blueGray[400],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<LeaveFamilyBloc, LeaveFamilyState>(
              listener: (context, state) {
                if (state is LeaveFamilyFailure) {
                  _dismissLoadingDialog();
                  Navigator.of(context).pop();
                  _onFailure(state.failure);
                } else if (state is LeaveFamilySuccess) {
                  isChange = true;
                  _dismissLoadingDialog();
                  _onSuccess(_l10n.leave);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                } else if (state is LeaveFamilyLoading) {
                  _showLoadingDialog();
                }
              },
            ),
            BlocListener<RemoveFamilyMemberBloc, RemoveFamilyMemberState>(
              listener: (context, state) {
                if (state is RemoveFamilyMemberFailure) {
                  _dismissLoadingDialog();
                  Navigator.of(context).pop();
                  _onFailure(state.failure);
                } else if (state is RemoveFamilyMemberSuccess) {
                  isChange = true;
                  _dismissLoadingDialog();
                  _onSuccess(_l10n.remove);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                } else if (state is RemoveFamilyMemberLoading) {
                  _showLoadingDialog();
                }
              },
            ),
            BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state.status == ProfileBlocStatus.success) {
                  _userId = NumParser.intParse(state.user?.id ?? '0');
                  setState(() {});
                }
              },
            ),
          ],
          child: BlocBuilder<FamilyMemberDetailBloc, FamilyMemberDetailState>(
            builder: (context, state) {
              if (state is FamilyMemberDetailSuccess) {
                _label = state.data.label;
                _label != widget.label ? isChange = true : isChange = false;
                return _SuccessContent(
                  successState: state,
                  loggedInUser:
                      _userId == widget.userId && widget.adminId != _userId,
                );
              } else if (state is FamilyMemberDetailFailure) {
                return const SizedBox();
                // FailureLoadMessage(
                //   onReloadData: () => _fetchData(1),
                //   message: state.failure.message,
                // );
              }

              return const ChartSkeleton();
            },
          ),
        ),
      ),
    );
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
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  void _showRemoveFamilyConfirmationSheet(BuildContext context, int id) {
    final _l10n = context.l10n;
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ActionableContentSheet(
          header: HeadingText2(text: _l10n.removeFamily),
          actions: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  _onRemove.call(id);
                },
                child: Text(_l10n.remove),
              ),
              const SizedBox(height: Dimens.small),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blueGray,
                ),
                child: Text(_l10n.cancel),
              ),
            ],
          ),
          content: Text(_l10n.removeFamilyConfirmation),
        );
      },
    );
  }

  void _showLeaveFamilyConfirmationSheet(BuildContext context, int id) {
    final _l10n = context.l10n;
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ActionableContentSheet(
          header: HeadingText2(text: _l10n.leaveFamily),
          actions: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _onLeave,
                child: Text(_l10n.leave),
              ),
              const SizedBox(height: Dimens.small),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blueGray,
                ),
                child: Text(_l10n.cancel),
              ),
            ],
          ),
          content: Text(_l10n.leaveFamilyConfirm),
        );
      },
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    Key? key,
    required this.loggedInUser,
    required this.successState,
  }) : super(key: key);

  final FamilyMemberDetailSuccess successState;
  final bool loggedInUser;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.dp32),
        child: Column(
          children: [
            GlucoseReportSection(
              loggedInUser: loggedInUser,
            ),
            const SizedBox(height: Dimens.dp32),
            InsulinReportSection(
              loggedInUser: loggedInUser,
            ),
            const SizedBox(height: Dimens.dp32),
            // CarbohydrateReportSection(),
            // SizedBox(height: Dimens.dp32),
          ],
        ),
      ),
    );
  }
}
