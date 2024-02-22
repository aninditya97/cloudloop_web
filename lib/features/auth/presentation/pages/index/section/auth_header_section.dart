import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/presentation/blocs/language/language_bloc.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthHeaderSection extends StatelessWidget {
  const AuthHeaderSection({
    Key? key,
    required this.state,
  }) : super(key: key);

  final LanguageState state;
  @override
  Widget build(BuildContext context) {
    return
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                MainAssets.logoVertical,
                width: 135,
                height: Dimens.dp28,
                color: AppColors.whiteColor,
              ),
              /*
              Text(
                ' by Curestream' ,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: Colors.white
                ),
                textAlign: TextAlign.left,
              ),  */
              TextButton(
                onPressed: () => _showDialogSelectLanguage(
                  context,
                  state.supportedLanguages,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language,
                      size: Dimens.large,
                      color: AppColors.whiteColor,
                    ),
                    const SizedBox(
                      width: Dimens.dp6,
                    ),
                    HeadingText4(
                      text: state.language?.code.toUpperCase() ??
                          context.l10n.localeName.toUpperCase(),
                      textColor: AppColors.whiteColor,
                    ),
                    const SizedBox(
                      width: Dimens.small,
                    ),
                    const Icon(
                      Icons.expand_more,
                      size: Dimens.large,
                      color: AppColors.whiteColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          /*
          Text(
            '        by Curestream' ,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Colors.white
            ),
            textAlign: TextAlign.left,
          ),  */
          ]
      );

      Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          MainAssets.logoVertical,
          width: 135,
          height: Dimens.dp28,
          color: AppColors.whiteColor,
        ),
        TextButton(
          onPressed: () => _showDialogSelectLanguage(
            context,
            state.supportedLanguages,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.language,
                size: Dimens.large,
                color: AppColors.whiteColor,
              ),
              const SizedBox(
                width: Dimens.dp6,
              ),
              HeadingText4(
                text: state.language?.code.toUpperCase() ??
                    context.l10n.localeName.toUpperCase(),
                textColor: AppColors.whiteColor,
              ),
              const SizedBox(
                width: Dimens.small,
              ),
              const Icon(
                Icons.expand_more,
                size: Dimens.large,
                color: AppColors.whiteColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _showDialogSelectLanguage(
  BuildContext context,
  List<Language> languages,
) {
  showDialog<Object?>(
    context: context,
    builder: (_) => SimpleDialog(
      children: languages
          .map(
            (lang) => ListTile(
              title: Text(lang.name),
              trailing: Text(lang.code.toUpperCase()),
              onTap: () {
                BlocProvider.of<LanguageBloc>(context)
                    .add(LanguageChanged(lang));
                Navigator.of(context).pop();
              },
            ),
          )
          .toList(),
    ),
  );
}
