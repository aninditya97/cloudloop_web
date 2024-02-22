import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class SearchUserSkeleton extends StatelessWidget {
  const SearchUserSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimens.appPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Skeleton(
                    height: Dimens.dp18,
                    width: 64,
                  ),
                ],
              ),
              const Skeleton(
                height: Dimens.dp36,
                width: 110,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
