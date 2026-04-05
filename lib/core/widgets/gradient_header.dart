import 'package:flutter/material.dart';
import 'package:diab_care/core/theme/app_colors.dart';

/// Unified gradient header used across all screens.
/// Provides consistent gradient background with rounded bottom corners.
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final double bottomRadius;
  final EdgeInsets padding;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.actions,
    this.bottom,
    this.bottomRadius = 28,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null || actions != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (leading != null) leading!,
                    if (leading == null) const SizedBox.shrink(),
                    if (actions != null)
                      Row(children: actions!)
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              if (leading != null || actions != null)
                const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              if (bottom != null) ...[
                const SizedBox(height: 20),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Unified search bar for headers.
class HeaderSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;

  const HeaderSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Rechercher...',
    this.onFilterTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                    onChanged('');
                  },
                )
              : onFilterTap != null
                  ? IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.primaryGreen),
                      onPressed: onFilterTap,
                    )
                  : null,
        ),
      ),
    );
  }
}
