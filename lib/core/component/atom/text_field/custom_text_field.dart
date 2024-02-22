import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    Key? key,
    this.controller,
    required this.formLabel,
    required this.hintText,
    this.suffixIcon,
    this.onTap,
    this.readOnly,
    this.onChanged,
    this.inputFormatters,
    this.inputType,
    this.errorText,
  }) : super(key: key);

  final TextEditingController? controller;
  final String formLabel;
  final String hintText;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final bool? readOnly;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? inputType;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeadingText4(
          text: formLabel,
        ),
        const SizedBox(height: Dimens.small),
        TextField(
          inputFormatters: inputFormatters,
          keyboardType: inputType,
          onTap: onTap,
          controller: controller,
          readOnly: readOnly ?? false,
          onChanged: onChanged,
          decoration: InputDecoration(
            errorText: errorText,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: Dimens.dp14,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.blueGray[200]!,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(Dimens.large),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
