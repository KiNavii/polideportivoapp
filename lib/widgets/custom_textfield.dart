import 'package:flutter/material.dart';
import 'package:deportivov1/constants/app_theme.dart';
import 'package:deportivov1/utils/responsive_util.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos tamaños adaptables según el dispositivo
    final labelFontSize = ResponsiveUtil.getAdaptiveTextSize(context, 14);
    final padding = ResponsiveUtil.getAdaptivePadding(
      context,
      AppTheme.paddingM,
    );
    final verticalPadding =
        maxLines > 1
            ? ResponsiveUtil.getAdaptivePadding(context, AppTheme.paddingM)
            : ResponsiveUtil.getAdaptivePadding(context, AppTheme.paddingS);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.darkColor,
            fontWeight: FontWeight.w500,
            fontSize: labelFontSize,
          ),
        ),
        SizedBox(height: ResponsiveUtil.getAdaptivePadding(context, 8)),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          autofocus: autofocus,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: ResponsiveUtil.getAdaptiveTextSize(context, 16),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                prefixIcon != null
                    ? Icon(
                      prefixIcon,
                      size: ResponsiveUtil.getAdaptiveTextSize(context, 20),
                    )
                    : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(color: AppTheme.lightGrayColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(color: AppTheme.lightGrayColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide(color: AppTheme.errorColor),
            ),
            filled: true,
            fillColor:
                enabled
                    ? Colors.white
                    : AppTheme.lightGrayColor.withOpacity(0.3),
            contentPadding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: verticalPadding,
            ),
            isDense: ResponsiveUtil.isSmallMobile(
              context,
            ), // Más compacto en pantallas pequeñas
          ),
        ),
      ],
    );
  }
}
