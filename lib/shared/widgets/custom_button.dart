import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final Widget? leading;
  final double height;
  final double borderRadius;
  final bool isGold;
  final Gradient? gradient;
  final bool hasShadow;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.leading,
    this.height = 54,
    this.borderRadius = 12,
    this.isGold = true,
    this.gradient,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ??
        (isGold
            ? AppGradients.gold
            : (backgroundColor == null ? AppGradients.navy : null));

    final effectiveColor =
        effectiveGradient == null ? (backgroundColor ?? AppColors.primary) : null;

    final glowShadow = hasShadow && onPressed != null
        ? [
            BoxShadow(
              color: isGold
                  ? const Color(0x40D97706) // rgba(217,119,6, 0.25)
                  : const Color(0x200F172A),
              blurRadius: isGold ? 24 : 16,
              offset: const Offset(0, 6),
            ),
          ]
        : null;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: effectiveColor,
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glowShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 8),
                      ] else if (icon != null) ...[
                        Icon(icon, size: 20, color: textColor ?? Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: textColor ?? Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

