import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class SearchUserComponent extends StatelessWidget {
  const SearchUserComponent({
    Key? key,
    required this.name,
    required this.id,
    required this.avatar,
    required this.status,
    this.onConnect,
    this.onRemove,
  }) : super(key: key);

  final String name;
  final int id;
  final String avatar;
  final ConnectionStatus status;
  final VoidCallback? onConnect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimens.appPadding),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox.fromSize(
                  size: const Size.fromRadius(Dimens.dp20), // Image radius
                  child: avatar.isNotEmpty
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, url, error) => ProfilePicture(
                            name: name,
                            fontsize: Dimens.dp28,
                            radius: Dimens.dp36,
                            count: 1,
                          ),
                        )
                      : ProfilePicture(
                          name: name,
                          fontsize: Dimens.dp28,
                          radius: Dimens.dp36,
                          count: 1,
                        ),
                ),
              ),
              const SizedBox(width: Dimens.dp8),
              Expanded(
                child: HeadingText4(
                  text: name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Dimens.dp8),
              SizedBox(
                width: 140,
                height: 50,
                child: _buildButton(context, status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, ConnectionStatus status) {
    if (status == ConnectionStatus.status1) {
      return ElevatedButton(
        onPressed: onConnect,
        child: Center(
          child: HeadingText4(
            text: context.l10n.connect,
            textColor: AppColors.whiteColor,
          ),
        ),
      );
    } else if (status == ConnectionStatus.status3) {
      return Center(
        child: Text(
          context.l10n.requestSend,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }
    return Center(
      child: Text(
        context.l10n.connected,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
