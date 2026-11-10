import 'package:flutter/material.dart';

class TimelineDayBadge extends StatelessWidget {
  const TimelineDayBadge({
    super.key,
    required this.dayNumber,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
    this.isHighlighted = false,
  });

  final int dayNumber;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final badge = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isHighlighted ? colorScheme.secondary : colorScheme.primary,
        shape: BoxShape.circle,
        border: isHighlighted
            ? Border.all(color: colorScheme.secondaryContainer, width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: (isHighlighted ? colorScheme.secondary : colorScheme.primary)
                .withValues(alpha: 0.28),
            blurRadius: isHighlighted ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$dayNumber',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top vertical connector line
        Container(
          width: 2,
          height: isFirst ? 8 : 16,
          color: isFirst
              ? Colors.transparent
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        // Ordinal circle badge (optionally interactive for position picking)
        if (onTap != null)
          Semantics(
            button: true,
            label: 'Stop number $dayNumber. Tap to change stop order.',
            child: Tooltip(
              message: 'Tap to change stop #$dayNumber order',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Padding(padding: const EdgeInsets.all(2), child: badge),
              ),
            ),
          )
        else
          badge,
        // Bottom vertical connector line
        Expanded(
          child: Container(
            width: 2,
            color: isLast
                ? Colors.transparent
                : colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
