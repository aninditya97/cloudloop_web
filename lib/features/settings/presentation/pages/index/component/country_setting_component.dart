import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class CountrySettingComponent extends StatefulWidget {
  const CountrySettingComponent({Key? key}) : super(key: key);

  @override
  State<CountrySettingComponent> createState() =>
      _CountrySettingComponentState();
}

class _CountrySettingComponentState extends State<CountrySettingComponent> {
  String _country = '';
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingMenuTile(
      title: Text(l10n.country),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeadingText4(text: _country),
          Icon(
            Icons.chevron_right_rounded,
            color: context.theme.primaryColor,
          ),
        ],
      ),
      onTap: () {
        showModalBottomSheet<void>(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          context: context,
          builder: (BuildContext context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(Dimens.appPadding),
                    width: 80,
                    child: Divider(
                      thickness: 4,
                      color: AppColors.blueGray[200],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.appPadding,
                  ),
                  child: HeadingText4(
                    text: l10n.country,
                    textColor: AppColors.blueGray[600],
                  ),
                ),
                Divider(
                  thickness: 1,
                  color: AppColors.blueGray[100],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: Dimens.appPadding,
                    right: Dimens.appPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Dimens.dp12),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search Country',
                          hintStyle: const TextStyle(
                            fontSize: Dimens.dp14,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.blueGray[200]!,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(Dimens.dp8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimens.dp18),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _country = 'Indonesia';
                            Navigator.pop(context);
                          });
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              MainAssets.flagID,
                              width: Dimens.appPadding,
                            ),
                            const SizedBox(width: Dimens.dp8),
                            const HeadingText4(
                              text: 'Indonesia',
                              textColor: Color(0xff333333),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primarySolidColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimens.dp24),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _country = 'Malaysia';
                            Navigator.pop(context);
                          });
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              MainAssets.flagMY,
                              width: Dimens.appPadding,
                            ),
                            const SizedBox(width: Dimens.dp8),
                            const HeadingText4(
                              text: 'Malaysia',
                              textColor: Color(0xff333333),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimens.dp24),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _country = 'England';
                            Navigator.pop(context);
                          });
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              MainAssets.flagGB,
                              width: Dimens.appPadding,
                            ),
                            const SizedBox(width: Dimens.dp8),
                            const HeadingText4(
                              text: 'English',
                              textColor: Color(0xff333333),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimens.dp24),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _country = 'Portugese';
                            Navigator.pop(context);
                          });
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              MainAssets.flagPT,
                              width: Dimens.appPadding,
                            ),
                            const SizedBox(width: Dimens.dp8),
                            const HeadingText4(
                              text: 'Portugese',
                              textColor: Color(0xff333333),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimens.dp24),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _country = 'Korea';
                            Navigator.pop(context);
                          });
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              MainAssets.flagKR,
                              width: Dimens.appPadding,
                            ),
                            const SizedBox(width: Dimens.dp8),
                            const HeadingText4(
                              text: 'Korea',
                              textColor: Color(0xff333333),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Dimens.dp24),
                    ],
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }
}
