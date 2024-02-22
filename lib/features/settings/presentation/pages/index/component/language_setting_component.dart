import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/presentation/blocs/language/language_bloc.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageSettingComponent extends StatelessWidget {
  const LanguageSettingComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return SettingMenuTile(
          title: Text(context.l10n.language),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeadingText4(text: state.language?.name ?? ''),
              Icon(
                Icons.chevron_right_rounded,
                color: context.theme.primaryColor,
              ),
            ],
          ),
          onTap: () => _showLanguageSelectorSheet(context),
        );
      },
    );
  }

  void _showLanguageSelectorSheet(BuildContext context) {
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, state) {
            final l10n = context.l10n;

            return ActionableContentSheet(
              header: HeadingText2(text: l10n.language),
              actions: ElevatedButton(
                child: Text(l10n.ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: state.supportedLanguages
                    .map(
                      (e) => ListTile(
                        minVerticalPadding: 0,
                        contentPadding: EdgeInsets.zero,
                        dense: false,
                        leading: Image.asset(
                          e.flag,
                          fit: BoxFit.cover,
                        ),
                        title: Text(e.name),
                        trailing: (e.code == state.language?.code)
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: context.theme.primaryColor,
                              )
                            : null,
                        onTap: () {
                          context.read<LanguageBloc>().add(LanguageChanged(e));
                        },
                      ),
                    )
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }
}
