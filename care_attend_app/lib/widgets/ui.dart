import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';

/// Frosted-glass surface for transient panels (drawer, bottom sheets, dialogs).
///
/// Blur is GPU-readback heavy, so this is used only on short-lived overlays —
/// never on always-on chrome — to keep continuous rendering smooth.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double sigma;
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.sigma = 18,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = Theme.of(context).colorScheme.surface;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: base.withValues(alpha: dark ? 0.78 : 0.80),
            borderRadius: borderRadius,
            border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.10 : 0.45),
                width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Shared UI building blocks. Screens compose these so spacing, elevation, and
/// states (loading/empty/error) are consistent everywhere — the main lever for a
/// cohesive, world-class feel.

/// Elevated surface card with consistent radius/padding/shadow.
///
/// Lifts subtly on pointer hover (web/desktop) for an interactive, polished
/// feel; no-op on touch devices.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  const AppCard({super.key, required this.child, this.padding = AppSpace.card, this.color});

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = dark
        ? (_hover ? cs.primary.withValues(alpha: 0.55) : AppColors.darkOutline)
        : (_hover ? cs.primary.withValues(alpha: 0.35) : Colors.transparent);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.color ?? cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: !dark
              ? (_hover
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4)),
                    ]
                  : AppShadow.card)
              : null,
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}

/// Screen-level title + optional subtitle.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const ScreenHeader(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: t.titleLarge),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpace.xs),
        Text(subtitle!, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    ]);
  }
}

/// Section label inside a card.
class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700));
}

/// Risk tier pill.
class RiskBadge extends StatelessWidget {
  final String tier;
  final double fontSize;
  const RiskBadge(this.tier, {super.key, this.fontSize = 14});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.riskColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text('${tier.toUpperCase()} RISK',
          style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }
}

/// Compact stat tile (value over label) used in dashboards.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const StatTile(this.value, this.label, this.color, {super.key});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

/// Empty state with icon + message + optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(children: [
        Icon(icon, size: 48, color: AppColors.grey),
        const SizedBox(height: AppSpace.md),
        Text(title, textAlign: TextAlign.center, style: t.titleMedium),
        if (message != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(message!, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
        if (action != null) ...[const SizedBox(height: AppSpace.lg), action!],
      ]),
    );
  }
}

/// Inline error card with optional retry.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView(this.message, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.riskHighBg,
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.riskHigh),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.riskHigh))),
        if (onRetry != null)
          TextButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).commonRetry)),
      ]),
    );
  }
}

/// Shimmer skeleton placeholder list while async content loads.
class SkeletonList extends StatefulWidget {
  final int count;
  final double height;
  const SkeletonList({super.key, this.count = 3, this.height = 72});
  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurfaceAlt
        : const Color(0xFFE6ECEF);
    final hi = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurface
        : const Color(0xFFF4F7F8);
    return Column(
      children: List.generate(widget.count, (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                return Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    gradient: LinearGradient(
                      begin: Alignment(-1 - _c.value * 2, 0),
                      end: Alignment(1 - _c.value * 2, 0),
                      colors: [base, hi, base],
                    ),
                  ),
                );
              },
            ),
          )),
    );
  }
}
