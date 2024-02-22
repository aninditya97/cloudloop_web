import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

class AlertSettingComponent extends StatefulWidget {
  const AlertSettingComponent({Key? key}) : super(key: key);

  @override
  State<AlertSettingComponent> createState() => _AlertSettingComponentState();
}

class _AlertSettingComponentState extends State<AlertSettingComponent> {
  bool light = false;

  var _switchValue = false;
  String _OnOff = 'Off';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingMenuTile(
      title: Text('${l10n.alerts}'),
      onTap: () async {
        // GoRouter.of(context).push('/alarm');
      },
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.theme.primaryColor,
      ),
    );
  }

  void _showSnoozeOptionsSheet() {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return ActionableContentSheet(
          header: HeadingText2(text: context.l10n.alerts),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.l10n.alerts}',
                style: TextStyle(
                  color: context.theme.primaryColor,
                  fontSize: Dimens.dp12,
                ),
              ),
              Switch(
                value: _switchValue,
                activeColor: Colors.red,
                onChanged: (value) {
                  setState(() {
                    _switchValue = value;
                  });
                },
              )
            ],
          ),
        );
      },
    );
  }
}
