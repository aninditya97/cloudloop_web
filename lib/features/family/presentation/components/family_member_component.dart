import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class FamilyMemberComponent extends StatelessWidget {
  const FamilyMemberComponent({
    Key? key,
    required this.avatar,
    required this.name,
    required this.statusLevel,
    required this.value,
    required this.onTap,
  }) : super(key: key);

  final String avatar;
  final BloodGlucoseLevel statusLevel;
  final String name;
  final double value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: Dimens.dp175,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimens.dp8),
          border: Border.all(
            color: AppColors.blueGray[200]!,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: Dimens.dp12,
                  right: Dimens.dp12,
                  top: Dimens.dp12,
                  bottom: Dimens.small,
                ),
                child: Column(
                  children: [
                    ClipOval(
                      child: SizedBox.fromSize(
                        size:
                            const Size.fromRadius(Dimens.dp20), // Image radius
                        child: avatar.isNotEmpty
                            ? Image.network(
                                avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (context, url, error) =>
                                    ProfilePicture(
                                  name: name,
                                  fontsize: Dimens.dp28,
                                  radius: Dimens.dp36,
                                  random: true,
                                  count: 1,
                                ),
                              )
                            : ProfilePicture(
                                name: name,
                                fontsize: Dimens.dp28,
                                radius: Dimens.dp36,
                                random: true,
                                count: 1,
                              ),
                      ),
                    ),
                    const SizedBox(height: Dimens.dp8),
                    HeadingText4(
                      text: name,
                    ),
                  ],
                ),
              ),
              Divider(
                color: AppColors.blueGray[100],
                thickness: Dimens.dp2,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.dp12,
                  vertical: Dimens.small,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      width: Dimens.dp36,
                      padding: const EdgeInsets.all(Dimens.dp8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: setBgColor(statusLevel),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(Dimens.small),
                        ),
                      ),
                      child: Image.asset(
                        bloodIcon(statusLevel),
                        width: Dimens.dp24,
                      ),
                    ),
                    Column(
                      children: [
                        HeadingText1(
                          text: value.roundToDouble().toString(),
                          textColor: setColor(statusLevel),
                        ),
                        Text(
                          'mg/dl',
                          style: TextStyle(
                            fontSize: Dimens.dp10,
                            color: setColor(statusLevel),
                          ),
                        )
                      ],
                    ),
                    Icon(
                      statusIcon(statusLevel),
                      size: Dimens.dp24,
                      color: setColor(statusLevel),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  IconData statusIcon(BloodGlucoseLevel status) {
    if (status == BloodGlucoseLevel.status1) {
      return Icons.error;
    } else if (status == BloodGlucoseLevel.status2) {
      return Icons.error;
    } else if (status == BloodGlucoseLevel.status3) {
      return Icons.check_circle;
    } else if (status == BloodGlucoseLevel.status4) {
      return Icons.warning;
    }
    return Icons.warning;
  }

  String bloodIcon(BloodGlucoseLevel status) {
    if (status == BloodGlucoseLevel.status1) {
      return MainAssets.bloodDropWarningIcon;
    } else if (status == BloodGlucoseLevel.status2) {
      return MainAssets.bloodDropWarningIcon;
    } else if (status == BloodGlucoseLevel.status3) {
      return MainAssets.bloodDropIcon;
    } else if (status == BloodGlucoseLevel.status4) {
      return MainAssets.bloodDropDangerIcon;
    }
    return MainAssets.bloodDropDangerIcon;
  }

  Color setColor(BloodGlucoseLevel status) {
    if (status == BloodGlucoseLevel.status1) {
      return Colors.amber;
    } else if (status == BloodGlucoseLevel.status2) {
      return Colors.amber;
    } else if (status == BloodGlucoseLevel.status3) {
      return AppColors.blueLevelColor;
    } else if (status == BloodGlucoseLevel.status4) {
      return Colors.red;
    }
    return Colors.red;
  }

  Color? setBgColor(BloodGlucoseLevel status) {
    if (status == BloodGlucoseLevel.status1) {
      return Colors.amber[50];
    } else if (status == BloodGlucoseLevel.status2) {
      return Colors.amber[50];
    } else if (status == BloodGlucoseLevel.status3) {
      return Colors.blue[50];
    } else if (status == BloodGlucoseLevel.status4) {
      return Colors.red[50];
    }
    return Colors.red[50];
  }
}
