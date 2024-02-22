import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class OverlapDataSection extends StatefulWidget {
  const OverlapDataSection({Key? key, this.onCheck}) : super(key: key);

  final ValueChanged<bool>? onCheck;

  @override
  State<OverlapDataSection> createState() => _OverlapDataSectionSectionState();
}

class _OverlapDataSectionSectionState extends State<OverlapDataSection> {
  @override
  void initState() {
    super.initState();
    _fetchData(1);
  }

  void _fetchData(int page) {
    context.read<InvitationsMemberBloc>().add(
          FetchInvitationsMemberEvent(
            page: page,
            perPage: 5,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvitationsMemberBloc, InvitationsMemberState>(
      builder: (context, state) {
        if (state is InvitationsMemberSuccess) {
          final itemList = state.data
              .where((e) => e.status == InvitationStatus.status3)
              .toList();
          if (itemList.isEmpty) {
            widget.onCheck?.call(true);
            return const SizedBox();
          } else {
            widget.onCheck?.call(false);
            return _SuccessContent(
              successState: state,
            );
          }
        } else if (state is InvitationsMemberFailure) {
          return const SizedBox();
        }

        return const SizedBox();
      },
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    Key? key,
    required this.successState,
  }) : super(key: key);

  final InvitationsMemberSuccess successState;

  Widget overlapped() {
    const overlap = Dimens.dp14;

    final stackLayers =
        List<Widget>.generate(successState.data.length, (index) {
      return Padding(
        padding: EdgeInsets.fromLTRB(index.toDouble() * overlap, 0, 0, 0),
        child: successState.data.length > 2
            ? index == successState.data.length - 1
                ? ClipOval(
                    child: SizedBox.fromSize(
                      size: const Size.fromRadius(Dimens.dp14), // Image radius
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.amber,
                        child: Text(
                          '${successState.data.length}+',
                          style: const TextStyle(fontSize: Dimens.dp10),
                        ),
                      ),
                    ),
                  )
                : ClipOval(
                    child: SizedBox.fromSize(
                      size: const Size.fromRadius(Dimens.dp14), // Image radius
                      child: Image.network(
                        successState.data[index].source!.avatar.toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, url, error) => ProfilePicture(
                          name: successState.data[index].source!.name,
                          fontsize: Dimens.dp18,
                          radius: Dimens.dp36,
                          count: 1,
                        ),
                      ),
                    ),
                  )
            : ClipOval(
                child: SizedBox.fromSize(
                  size: const Size.fromRadius(Dimens.dp14), // Image radius
                  child: Image.network(
                    successState.data[index].source!.avatar.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, url, error) => ProfilePicture(
                      name: successState.data[index].source!.name,
                      fontsize: Dimens.dp18,
                      radius: Dimens.dp36,
                      count: 1,
                    ),
                  ),
                ),
              ),
      );
    });

    return Stack(children: stackLayers);
  }

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Container(
      width: MediaQuery.of(context).size.width,
      height: Dimens.dp50,
      decoration: BoxDecoration(
        color: AppColors.blueGray[100],
        borderRadius: BorderRadius.circular(Dimens.dp8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.appPadding,
          vertical: Dimens.dp10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                overlapped(),
                const SizedBox(width: Dimens.dp6),
                HeadingText4(text: _l10n.pendingInvitation)
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => const PendingInvitationFamilyPage(),
                  ),
                );
              },
              child: HeadingText4(
                text: _l10n.viewAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
