import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Full-screen luxury atmospheric background with ambient mesh glow spheres and micro-particles
class AuthAmbientBackground extends StatelessWidget {
  final Widget child;

  const AuthAmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080C14) : const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // Ambient Glow Spheres & Depth Painter
          Positioned.fill(
            child: CustomPaint(
              painter: _AuthAmbientGlowPainter(isDark: isDark),
            ),
          ),

          // Subtle Noise / Vignette Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    isDark ? Colors.black.withAlpha(60) : Colors.black.withAlpha(10),
                  ],
                ),
              ),
            ),
          ),

          // Foreground Content with Safe Area
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _AuthAmbientGlowPainter extends CustomPainter {
  final bool isDark;

  _AuthAmbientGlowPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Top-Left Orb (Vibrant Indigo & Deep Violet)
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6366F1).withAlpha(isDark ? 65 : 35),
          const Color(0xFF8B5CF6).withAlpha(isDark ? 30 : 15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.15, size.height * 0.12),
        radius: size.width * 0.75,
      ));
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.12), size.width * 0.75, p1);

    // 2. Center-Right Orb (Cyber Sky & Cyan)
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0EA5E9).withAlpha(isDark ? 55 : 30),
          const Color(0xFF06B6D4).withAlpha(isDark ? 25 : 12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.92, size.height * 0.42),
        radius: size.width * 0.8,
      ));
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.42), size.width * 0.8, p2);

    // 3. Bottom-Left Orb (Emerald Glow)
    final p3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF10B981).withAlpha(isDark ? 40 : 20),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.25, size.height * 0.88),
        radius: size.width * 0.65,
      ));
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.88), size.width * 0.65, p3);

    // 4. Subtle Specular Highlight Orbs for 3D Visual Depth
    final p4 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(isDark ? 12 : 18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.25),
        radius: size.width * 0.4,
      ));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.25), size.width * 0.4, p4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Frosted Glass Card Container with border highlight and smooth shadow
class AuthGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AuthGlassCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF121A2C).withAlpha(210)
                : Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(28)
                  : const Color(0xFFE2E8F0),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x7F000000)
                    : const Color(0x144338CA),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.white.withAlpha(200),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Floating Hero Emblem with 3D glowing gradient and multi-layered ring
class AuthHeaderEmblem extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final double size;

  const AuthHeaderEmblem({
    super.key,
    required this.icon,
    this.accentColor = const Color(0xFF6366F1),
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Outer Pulse Glow Ring
          Container(
            width: size * 1.35,
            height: size * 1.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withAlpha(isDark ? 70 : 45),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Outer Concentric Ring
          Container(
            width: size * 1.15,
            height: size * 1.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withAlpha(isDark ? 60 : 35),
                width: 1.5,
              ),
            ),
          ),

          // Core 3D Gradient Squircle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor,
                  const Color(0xFF4F46E5),
                  const Color(0xFF0EA5E9),
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.34),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withAlpha(isDark ? 150 : 100),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withAlpha(isDark ? 100 : 60),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top-Left Light Specular Flare
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    width: size * 0.4,
                    height: size * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withAlpha(120),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Icon
                Icon(
                  icon,
                  color: Colors.white,
                  size: size * 0.48,
                ),
              ],
            ),
          ),

          // Floating Mini Sparkle Badge
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF080C14) : Colors.white,
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x6610B981),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Interactive Input Field with animated focus ring, clear button, and custom icons
class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
      decoration: BoxDecoration(
        color: isDark
            ? (_isFocused ? const Color(0xFF1E293B) : const Color(0xFF0F172A).withAlpha(190))
            : (_isFocused ? Colors.white : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (_isFocused) ...[
            BoxShadow(
              color: AppTheme.primary.withAlpha(isDark ? 65 : 35),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: isDark ? Colors.black.withAlpha(80) : const Color(0xFF6366F1).withAlpha(15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] else ...[
            BoxShadow(
              color: isDark ? Colors.black.withAlpha(35) : const Color(0xFF94A3B8).withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isFocused
                  ? AppTheme.primary.withAlpha(isDark ? 55 : 30)
                  : (isDark ? const Color(0xFF334155).withAlpha(80) : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              color: _isFocused
                  ? AppTheme.primary
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _isFocused
                        ? AppTheme.primary
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
                TextField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  onChanged: widget.onChanged,
                  cursorColor: AppTheme.primary,
                  cursorWidth: 2,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.suffixIcon != null) widget.suffixIcon!,
        ],
      ),
    );
  }
}

/// Primary Glowing CTA Button with shimmer and responsive sizing
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final List<Color>? gradientColors;
  final Color? glowColor;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradientColors,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? const [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF0EA5E9)];
    final glow = glowColor ?? const Color(0xFF6366F1);

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glow.withAlpha(125),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0EA5E9).withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: Colors.white, size: 18),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// Frosted Social & Fast Auth Button with full responsiveness
class AuthSocialButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;

  const AuthSocialButton({
    super.key,
    required this.label,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF1E293B).withAlpha(160) : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Symmetrical OR Divider
class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }
}
