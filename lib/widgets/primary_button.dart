import 'package:flutter/material.dart';
import 'package:stynext/core/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String? label;
  final String? text;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const PrimaryButton({
    super.key,
    this.label,
    this.text,
    this.onPressed,
    this.fullWidth = true,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final display = label ?? text ?? '';
    final child = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        padding:
            padding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      child: Text(display),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}
