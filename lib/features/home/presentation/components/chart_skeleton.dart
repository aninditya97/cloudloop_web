import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class ChartSkeleton extends StatelessWidget {
  const ChartSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(Dimens.dp16),
          child: Column(
            children: [
              Row(
                children: const [
                  Skeleton(
                    height: Dimens.dp36,
                    width: Dimens.dp36,
                  ),
                  SizedBox(width: Dimens.dp16),
                  Expanded(
                    child:
                        Skeleton(height: Dimens.dp16, width: double.infinity),
                  ),
                ],
              ),
              const SizedBox(height: Dimens.dp8),
              const Skeleton(
                height: Dimens.dp175,
                width: double.infinity,
              ),
              const SizedBox(height: Dimens.dp18),
              Row(
                children: const [
                  Skeleton(
                    height: Dimens.dp36,
                    width: Dimens.dp36,
                  ),
                  SizedBox(width: Dimens.dp16),
                  Expanded(
                    child:
                        Skeleton(height: Dimens.dp16, width: double.infinity),
                  ),
                ],
              ),
              const SizedBox(height: Dimens.dp8),
              const Skeleton(
                height: Dimens.dp175,
                width: double.infinity,
              )
            ],
          ),
        ),
      ],
    );
  }
}
