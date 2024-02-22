import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class PendingInvitationSkeleton extends StatelessWidget {
  const PendingInvitationSkeleton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      child: const Skeleton(
                        height: Dimens.dp48,
                        width: Dimens.dp48,
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimens.dp12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(
                        height: Dimens.dp18,
                        width: Dimens.dp75,
                      ),
                      SizedBox(height: Dimens.small),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Dimens.dp12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    child: SizedBox(
                      height: Dimens.dp36,
                      child: Skeleton(),
                    ),
                  ),
                  SizedBox(width: Dimens.dp12),
                  Expanded(
                    child: SizedBox(
                      height: Dimens.dp36,
                      child: Skeleton(),
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
