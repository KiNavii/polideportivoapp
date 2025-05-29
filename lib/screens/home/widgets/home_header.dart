import 'package:flutter/material.dart';
import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/models/user_model.dart';
import 'package:deportivov1/utils/responsive_util.dart';

class HomeHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onProfileTap;

  const HomeHeader({super.key, this.user, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final userName = user?.nombre ?? '';
    final userInitials =
        userName.isNotEmpty
            ? userName
                .split(' ')
                .take(2)
                .map((s) => s.isNotEmpty ? s[0] : '')
                .join('')
                .toUpperCase()
            : '?';

    final double headerFontSize = ResponsiveUtil.getAdaptiveTextSize(
      context,
      32,
    );
    final double padding = ResponsiveUtil.getAdaptivePadding(context, 20);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: ResponsiveUtil.getAdaptivePadding(context, 70),
        left: padding,
        right: padding,
        bottom: ResponsiveUtil.getAdaptivePadding(context, 15),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: ResponsiveUtil.getAdaptiveTextSize(context, 16),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName.isNotEmpty ? userName : 'Usuario',
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: ResponsiveUtil.getAdaptiveHeight(context, 50),
              height: ResponsiveUtil.getAdaptiveHeight(context, 50),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  userInitials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtil.getAdaptiveTextSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días';
    } else if (hour < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }
}
