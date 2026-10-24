import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../theme/unicart_theme.dart";

class RetailerChannelSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final bool sharedAccess;

  const RetailerChannelSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.sharedAccess = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UniCartColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: UniCartColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "PICK YOUR SHOPPING CHANNEL",
                  style: TextStyle(
                    color: UniCartColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              _AccessPill(shared: sharedAccess),
            ],
          ),
          const SizedBox(height: 12),
          // IntrinsicHeight is required: a Row that stretches its children has
          // no height limit inside a scrolling list, which makes Flutter throw
          // a layout error and the whole lobby body renders blank.
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ChannelCard(
                  title: "Temu",
                  subtitle: "Gadgets, room setup & everyday finds",
                  tag: "Budget picks",
                  icon: Icons.shopping_bag_rounded,
                  selected: selected == "temu",
                  gradient: const [Color(0xFFFF9A1F), Color(0xFFFF4B2B)],
                  glow: const Color(0xFFFF6A1F),
                  onTap: () => onSelected("temu"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChannelCard(
                  title: "SHEIN",
                  subtitle: "Fits, fashion & campus style",
                  tag: "Trending",
                  icon: Icons.checkroom_rounded,
                  selected: selected == "shein",
                  gradient: const [Color(0xFF1B1B2F), Color(0xFFE0338A)],
                  glow: const Color(0xFFE0338A),
                  onTap: () => onSelected("shein"),
                ),
              ),
            ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sharedAccess
                ? "Shared access is active. Each channel keeps its own goal, items, payments and batch."
                : "₦2,000 unlocks the current Temu and SHEIN lobbies. Each ends when it reaches its goal.",
            style: TextStyle(
              color: UniCartColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessPill extends StatelessWidget {
  final bool shared;
  const _AccessPill({required this.shared});

  @override
  Widget build(BuildContext context) {
    final color = shared ? UniCartColors.success : UniCartColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(shared ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
              size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            shared ? "Both unlocked" : "1 payment unlocks both",
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final bool selected;
  final List<Color> gradient;
  final Color glow;
  final VoidCallback onTap;

  const _ChannelCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.selected,
    required this.gradient,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(19);
    final titleColor = selected ? Colors.white : UniCartColors.textPrimary;
    final secondaryColor = selected
        ? Colors.white.withValues(alpha: 0.86)
        : UniCartColors.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient)
            : null,
        color: selected ? null : UniCartColors.surfaceRaised,
        borderRadius: radius,
        border: Border.all(color: selected ? glow.withValues(alpha: 0.8) : UniCartColors.border),
        boxShadow: selected
            ? [BoxShadow(color: glow.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 7))]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            if (!selected) HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 25, color: titleColor),
                const SizedBox(height: 10),
                Text(title, style: TextStyle(color: titleColor, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: secondaryColor, fontSize: 11, height: 1.35)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withValues(alpha: 0.17) : glow.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(tag, style: TextStyle(color: selected ? Colors.white : glow, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 15, color: selected ? Colors.white : UniCartColors.textMuted),
                    const SizedBox(width: 5),
                    Text(selected ? "Selected" : "Choose channel",
                        style: TextStyle(color: selected ? Colors.white : UniCartColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
