import "package:flutter/material.dart";
import "../theme/unicart_theme.dart";

class UniCartBackdrop extends StatelessWidget {
  final Widget child;
  final bool safeArea;

  const UniCartBackdrop({
    super.key,
    required this.child,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                UniCartColors.background,
                UniCartColors.backgroundAlt,
                UniCartColors.background,
              ],
            ),
          ),
        ),
        const Positioned(
          top: -140,
          right: -120,
          child: _AmbientOrb(
            size: 360,
            color: Color(0x292563EB),
          ),
        ),
        const Positioned(
          bottom: -180,
          left: -120,
          child: _AmbientOrb(
            size: 340,
            color: Color(0x1F3B82F6),
          ),
        ),
        child,
      ],
    );

    return safeArea ? SafeArea(child: content) : content;
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class UniCartPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool elevated;

  const UniCartPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = UniCartRadius.xl,
    this.color,
    this.borderColor,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? UniCartColors.surfaceGlass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? UniCartColors.borderGlass,
        ),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }
}

class UniCartPrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  final IconData? leadingIcon;
  final bool outlined;
  final Color? accentColor;
  final double minHeight;

  const UniCartPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.leadingIcon,
    this.outlined = false,
    this.accentColor,
    this.minHeight = 54,
  });

  @override
  State<UniCartPrimaryButton> createState() => _UniCartPrimaryButtonState();
}

class _UniCartPrimaryButtonState extends State<UniCartPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final accent = widget.accentColor ?? UniCartColors.primary;
    final accentEnd = Color.lerp(accent, Colors.white, 0.16) ?? accent;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: widget.outlined
                ? (_pressed ? UniCartColors.surfaceSoft : Colors.transparent)
                : null,
            gradient: widget.outlined
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: enabled
                        ? [accent, accentEnd]
                        : [
                            UniCartColors.surfaceSoft,
                            UniCartColors.surfaceSoft,
                          ],
                  ),
            borderRadius: BorderRadius.circular(UniCartRadius.md),
            border: Border.all(
              color: widget.outlined
                  ? (enabled
                      ? accent.withValues(alpha: 0.55)
                      : UniCartColors.divider)
                  : (_pressed
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.transparent),
            ),
            boxShadow: !widget.outlined && enabled && !_pressed
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: enabled ? (_pressed ? 0.86 : 1) : 0.45,
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.leadingIcon != null) ...[
                          Icon(
                            widget.leadingIcon,
                            size: 19,
                            color: widget.outlined ? accent : Colors.white,
                          ),
                          const SizedBox(width: 10),
                        ],
                        DefaultTextStyle.merge(
                          style: TextStyle(
                            color: widget.outlined ? accent : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          child: widget.child,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class UniCartIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? foregroundColor;

  const UniCartIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: UniCartColors.surfaceRaised,
        borderRadius: BorderRadius.circular(UniCartRadius.sm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(UniCartRadius.sm),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UniCartRadius.sm),
              border: Border.all(color: UniCartColors.border),
            ),
            child: Icon(
              icon,
              size: 20,
              color: foregroundColor ?? UniCartColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class UniCartLogoMark extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const UniCartLogoMark({
    super.key,
    this.size = 72,
    this.showWordmark = false,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10203A), Color(0xFF0A1425)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: UniCartColors.borderGlass),
        boxShadow: const [
          BoxShadow(
            color: UniCartColors.primaryGlow,
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset(
        "assets/images/logo.png",
        fit: BoxFit.contain,
        semanticLabel: "UniCart logo",
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 14),
        const Text(
          "UniCart",
          style: TextStyle(
            color: UniCartColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class UniCartEyebrow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const UniCartEyebrow({
    super.key,
    required this.icon,
    required this.label,
    this.color = UniCartColors.primarySoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class UniCartStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const UniCartStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class UniCartInfoBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? message;

  const UniCartInfoBanner({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(UniCartRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: const TextStyle(
                      color: UniCartColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UniCartMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color accent;

  const UniCartMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.16),
            UniCartColors.surfaceRaised,
          ],
        ),
        borderRadius: BorderRadius.circular(UniCartRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  color: UniCartColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: UniCartColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 3),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: UniCartColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UniCartSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const UniCartSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: UniCartColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: UniCartColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

void showUniCartSnack(
  BuildContext context,
  String message, {
  bool success = false,
  bool warning = false,
}) {
  final color = success
      ? UniCartColors.success
      : warning
          ? UniCartColors.warning
          : UniCartColors.danger;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: UniCartColors.surfaceRaised,
        content: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success
                    ? Icons.check_rounded
                    : warning
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                size: 17,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: UniCartColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
