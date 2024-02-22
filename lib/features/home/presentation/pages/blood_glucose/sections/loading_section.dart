import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class LoadingSection extends StatelessWidget {
  const LoadingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.dp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Dimens.dp20),
          const Skeleton(width: double.infinity, height: Dimens.dp200),
          const SizedBox(height: Dimens.dp20),
          const Skeleton(width: double.infinity, height: Dimens.dp16),
          const SizedBox(height: Dimens.dp16),
          Skeleton(width: Dimens.width(context) * 6, height: Dimens.dp16),
          const SizedBox(height: Dimens.dp16),
          Skeleton(width: Dimens.width(context) * 4, height: Dimens.dp16),
          const SizedBox(height: Dimens.dp16),
          Skeleton(width: Dimens.width(context) * 8, height: Dimens.dp16),
          const SizedBox(height: Dimens.dp16),
          Skeleton(width: Dimens.width(context) * 5, height: Dimens.dp16),
        ],
      ),
    );
  }
}
