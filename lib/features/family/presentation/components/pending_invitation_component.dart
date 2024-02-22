import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class PendingInvitationComponent extends StatelessWidget {
  const PendingInvitationComponent({
    Key? key,
    required this.name,
    required this.id,
    required this.userId,
    required this.avatar,
    required this.status,
    required this.onAccepted,
    required this.onRejected,
  }) : super(key: key);

  final String name;
  final String userId;
  final int id;
  final String avatar;
  final String status;
  final ValueChanged<int> onAccepted;
  final ValueChanged<int> onRejected;

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.appPadding,
            vertical: Dimens.appPadding,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipOval(
                    child: SizedBox.fromSize(
                      size: const Size.fromRadius(Dimens.dp20), // Image radius
                      child: avatar.isNotEmpty == true
                          ? Image.network(
                              avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (context, url, error) =>
                                  ProfilePicture(
                                name: name,
                                fontsize: Dimens.dp28,
                                radius: Dimens.dp36,
                                count: 1,
                              ),
                            )
                          : ProfilePicture(
                              name: name,
                              fontsize: Dimens.dp28,
                              radius: Dimens.dp36,
                              count: 1,
                            ),
                    ),
                  ),
                  const SizedBox(width: Dimens.dp12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeadingText4(
                        text: name,
                      ),
                      // const SizedBox(height: Dimens.small),
                      // SubtitleText(
                      //   text: '#$userId',
                      //   textColor: AppColors.blueGray[400],
                      // ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Dimens.dp12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: Dimens.dp40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: AppColors.blueGray[200]!),
                            borderRadius: BorderRadius.circular(Dimens.dp8),
                          ),
                        ),
                        onPressed: () {
                          onRejected.call(id);
                        },
                        child: Center(
                          child: HeadingText4(
                            text: _l10n.reject,
                            textColor: AppColors.blueGray[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimens.dp12),
                  Expanded(
                    child: SizedBox(
                      height: Dimens.dp40,
                      child: ElevatedButton(
                        onPressed: () {
                          onAccepted.call(id);
                        },
                        child: Center(
                          child: HeadingText4(
                            text: _l10n.accept,
                            textColor: AppColors.whiteColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
