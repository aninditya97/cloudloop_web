import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/presentation/bloc/update_family/update_family_bloc.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:get_it/get_it.dart';

class EditFamilyNamePage extends StatelessWidget {
  const EditFamilyNamePage({
    Key? key,
    required this.id,
    required this.name,
    required this.label,
    required this.avatar,
  }) : super(key: key);

  final int id;
  final String name;
  final String label;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<UpdateFamilyBloc>(),
      child: _EditFamilyNameView(
        id: id,
        name: name,
        label: label,
        avatar: avatar,
      ),
    );
  }
}

class _EditFamilyNameView extends StatefulWidget {
  const _EditFamilyNameView({
    Key? key,
    required this.id,
    required this.name,
    required this.label,
    required this.avatar,
  }) : super(key: key);

  final int id;
  final String name;
  final String label;
  final String avatar;

  @override
  State<_EditFamilyNameView> createState() => _EditFamilyNameViewState();
}

class _EditFamilyNameViewState extends State<_EditFamilyNameView> {
  bool _isLoadingDialogOpen = false;
  final _labelController = TextEditingController();

  void _onUpdate() {
    context
        .read<UpdateFamilyBloc>()
        .add(UpdateFamilyFetched(id: widget.id, label: _labelController.text));
  }

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        foregroundColor: AppColors.primarySolidColor,
        centerTitle: true,
        title: HeadingText4(
          text: _l10n.editFamily,
          textColor: Colors.black,
        ),
      ),
      body: BlocListener<UpdateFamilyBloc, UpdateFamilyState>(
        listener: (context, state) {
          if (state is UpdateFamilyFailure) {
            _dismissLoadingDialog();
            _onFailure(state.failure);
          } else if (state is UpdateFamilySuccess) {
            _dismissLoadingDialog();
            _onSuccess(_l10n.dataUpdated);
          } else if (state is UpdateFamilyLoading) {
            _showLoadingDialog();
          }
        },
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimens.dp24,
                    horizontal: Dimens.appPadding,
                  ),
                  child: Column(
                    children: [
                      ClipOval(
                        child: SizedBox.fromSize(
                          size: const Size.fromRadius(20), // Image radius
                          child: widget.avatar.isNotEmpty
                              ? Image.network(
                                  widget.avatar,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, url, error) =>
                                      ProfilePicture(
                                    name: widget.name,
                                    fontsize: Dimens.dp28,
                                    radius: Dimens.dp36,
                                    count: 1,
                                  ),
                                )
                              : ProfilePicture(
                                  name: widget.name,
                                  fontsize: Dimens.dp28,
                                  radius: Dimens.dp36,
                                  count: 1,
                                ),
                        ),
                      ),
                      const SizedBox(height: Dimens.dp8),
                      HeadingText4(text: widget.name),
                      const SizedBox(height: Dimens.small),
                      SubtitleText(text: widget.label),
                      const SizedBox(height: Dimens.appPadding),
                      CustomTextField(
                        controller: _labelController,
                        formLabel: _l10n.familyLabel,
                        hintText: widget.label.isNotEmpty
                            ? widget.label
                            : _l10n.familyStatus,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.appPadding,
            ),
            child: ElevatedButton(
              onPressed: _labelController.text.isNotEmpty ? _onUpdate : null,
              child: HeadingText4(
                text: _l10n.save,
                textColor: AppColors.whiteColor,
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(
              left: Dimens.appPadding,
              right: Dimens.appPadding,
              bottom: Dimens.appPadding,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whiteColor,
                side: BorderSide(
                  color: AppColors.blueGray[200]!,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: HeadingText4(
                text: _l10n.discard,
                textColor: AppColors.blueGray[400],
              ),
            ),
          ),
        ],
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

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }
}
