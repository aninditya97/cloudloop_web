import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class FamilyMemberSkeleton extends StatelessWidget {
  const FamilyMemberSkeleton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimens.dp175,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimens.dp8),
        border: Border.all(
          color: AppColors.blueGray[200]!,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: Dimens.dp12,
                right: Dimens.dp12,
                top: Dimens.dp12,
                bottom: Dimens.small,
              ),
              child: Column(
                children: [
                  ClipOval(
                    child: SizedBox.fromSize(
                      size: const Size.fromRadius(20), // Image radius
                      child: const Skeleton(
                        height: Dimens.dp48,
                        width: Dimens.dp48,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimens.dp8),
                  const Skeleton(
                    height: Dimens.dp18,
                    width: 64,
                  ),
                ],
              ),
            ),
            Divider(
              color: AppColors.blueGray[100],
              thickness: Dimens.dp2,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.dp12,
                vertical: Dimens.small,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Container(
                  //   width: Dimens.dp36,
                  //   padding: const EdgeInsets.all(Dimens.dp8),
                  //   alignment: Alignment.center,

                  //   child: Image.asset(
                  //     bloodIcon,
                  //     width: Dimens.dp24,
                  //   ),
                  // ),
                  Column(
                    children: const [
                      Skeleton(
                        height: Dimens.dp18,
                        width: 64,
                      ),
                      Skeleton(
                        height: Dimens.dp18,
                        width: 64,
                      ),
                    ],
                  ),
                  const Skeleton(
                    height: Dimens.dp24,
                    width: Dimens.dp24,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
