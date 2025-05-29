import 'package:flutter/material.dart';
import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/utils/responsive_util.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = ResponsiveUtil.getAdaptiveTextSize(context, 18);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.primaryColor, size: fontSize + 2),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
            ),
          ],
        ),
        if (actionText != null && onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText!,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtil.getAdaptiveTextSize(context, 14),
              ),
            ),
          ),
      ],
    );
  }
}
