import 'package:cloudloop_mobile/core/preferences/dimens.dart';
import 'package:flutter/material.dart';

class ErrorMessageWidget extends StatelessWidget {
  const ErrorMessageWidget({
    Key? key,
    required this.onPress,
    required this.message,
  }) : super(key: key);

  final VoidCallback? onPress;
  final String? message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimens.dp24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message ?? 'Sepertinya sedang terjadi suatu masalah...',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimens.dp16),
          ElevatedButton(
            onPressed: onPress,
            child: const Text('reload'),
          ),
        ],
      ),
    );
  }
}
