import 'package:flutter/material.dart';

class OnboardingPageIndicator extends StatelessWidget {
  final int totalCount;
  final int currentIndex;
  final Color activeColor;

  const OnboardingPageIndicator({
    super.key,
    required this.totalCount,
    required this.currentIndex,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? activeColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(120),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
